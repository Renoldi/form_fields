import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:form_fields/src/controllers/form_fields_my_image_controller.dart';
import 'package:form_fields/src/providers/form_fields_my_image_provider.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/utilities/enums.dart';
import 'package:form_fields/src/utilities/upload_response_mapper.dart';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'pending_upload_store.dart';

final _log = Logger('OfflineUploadManager');

/// Keeps registered `FormFieldsMyImageController` / `FormFieldsMyImageProvider`
/// instances and marks matching images as uploaded when a persisted (offline)
/// upload succeeds. Successes that cannot be matched yet are buffered and
/// re-applied when a matching controller or provider registers or changes.
class OfflineUploadManager {
  OfflineUploadManager._();

  static final OfflineUploadManager instance = OfflineUploadManager._();

  /// Pending successes older than this are discarded.
  static const Duration _pendingTtl = Duration(hours: 24);

  /// Upper bound for buffered successes; the oldest entry is dropped first.
  static const int _maxPending = 100;

  final Map<FormFieldsMyImageController, VoidCallback> _controllers = {};
  final Map<FormFieldsMyImageProvider, VoidCallback> _providers = {};
  final Map<String, _ImageLocation> _locations = {};
  final List<_PendingSuccess> _pending = [];

  /// Durable copy of [_pending]. Null until [restorePending] is called, in
  /// which case the buffer lives in memory only.
  PendingUploadStore? _store;

  /// Re-entrancy guard: `setImages` notifies listeners synchronously, which
  /// calls back into [_drainPending]. Without this guard the same pending
  /// entry would be re-applied recursively.
  bool _draining = false;

  /// Loads the pending buffer saved by a previous session from [file] and
  /// keeps it in sync with that file from now on. Entries are applied as
  /// soon as a matching image registers or changes. Call once at startup.
  Future<void> restorePending(File file) async {
    final store = PendingUploadStore(file);
    _store = store;

    final records = await store.read();
    var restored = 0;
    for (final record in records) {
      final entry = _PendingSuccess.fromJson(record);
      if (entry == null) continue;
      _insertPending(entry);
      restored++;
    }
    _trimPending();
    // Only rewrite when there is something to keep or clean up.
    if (records.isNotEmpty) await _persistPending();
    _log.info('restored $restored pending upload(s) from ${file.path}');
  }

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  void registerController(FormFieldsMyImageController controller) {
    if (_controllers.containsKey(controller)) return;
    void listener() => _tryApplyPendingToController(controller);
    controller.addListener(listener);
    _controllers[controller] = listener;
    _log.fine('registerController total=${_controllers.length}');
    // Apply any buffered successes to the newly registered controller.
    _tryApplyPendingToController(controller);
  }

  void unregisterController(FormFieldsMyImageController controller) {
    final listener = _controllers.remove(controller);
    if (listener != null) controller.removeListener(listener);
    _log.fine('unregisterController total=${_controllers.length}');
  }

  void registerProvider(FormFieldsMyImageProvider provider) {
    if (_providers.containsKey(provider)) return;
    void listener() => _tryApplyPendingToProvider(provider);
    provider.addListener(listener);
    _providers[provider] = listener;
    _log.fine('registerProvider total=${_providers.length}');
    _tryApplyPendingToProvider(provider);
    updateProviderLocations(provider, provider.images);
  }

  void unregisterProvider(FormFieldsMyImageProvider provider) {
    final listener = _providers.remove(provider);
    if (listener != null) provider.removeListener(listener);
    _locations.removeWhere((_, loc) => loc.provider == provider);
    _log.fine('unregisterProvider total=${_providers.length}');
  }

  /// Update registry of correlation id -> provider+index locations.
  void updateProviderLocations(
    FormFieldsMyImageProvider provider,
    List<MyImageResult> images,
  ) {
    _locations.removeWhere((_, loc) => loc.provider == provider);
    for (var i = 0; i < images.length; i++) {
      final corr = images[i].payload['uploadCorrelationId']?.toString();
      if (corr != null) _locations[corr] = _ImageLocation(provider, i);
    }
  }

  // ---------------------------------------------------------------------------
  // Upload success
  // ---------------------------------------------------------------------------

  /// Called when an upload for a persisted payload succeeded. Marks the
  /// matching image as `MyImageStatus.uploaded` (and fills link/id when
  /// available) in a registered controller or provider. Unmatched successes
  /// are buffered until a matching target registers or changes.
  void notifyUploadSuccess(Map<String, dynamic> persisted, Response resp) {
    try {
      final ref = _PersistedRef.from(persisted);
      final result = _UploadResult.from(persisted, resp);
      _log.fine(
        'notifyUploadSuccess link=${result.link} '
        'imageId=${result.imageId} controllers=${_controllers.length}',
      );

      var matched = _applyViaRegistry(ref, result);

      // Controllers are always attempted so every visible widget updates.
      for (final controller in _controllers.keys.toList()) {
        final hit = _applyToController(controller, ref, result);
        matched = hit || matched;
      }

      // Providers are only consulted when no controller matched.
      if (!matched) {
        for (final provider in _providers.keys.toList()) {
          final hit = _applyToProvider(provider, ref, result);
          matched = hit || matched;
        }
      }

      if (!matched) {
        _insertPending(
          _PendingSuccess(
            persisted: persisted,
            result: result,
            createdAt: DateTime.now(),
          ),
        );
        _trimPending();
        _persistPending();
        _log.fine('queued pending success (${_pending.length})');
      }
    } catch (e, st) {
      _log.warning('notifyUploadSuccess failed', e, st);
    }
  }

  /// Quick path: if the persisted payload carries a correlation id that maps
  /// to a known provider index, update that slot directly.
  bool _applyViaRegistry(_PersistedRef ref, _UploadResult result) {
    final corr = ref.correlationId;
    if (corr == null) return false;
    final loc = _locations[corr];
    if (loc == null) return false;

    final images = loc.provider.images.toList();
    if (loc.index < 0 || loc.index >= images.length) return false;
    // The cached index can go stale when the list changes without going
    // through the field. Only trust it when the image at that index still
    // carries the same correlation id.
    if (images[loc.index].payload['uploadCorrelationId']?.toString() != corr) {
      _locations.remove(corr);
      return false;
    }

    images[loc.index] = _markUploaded(images[loc.index], result);
    loc.provider.setImages(images);
    _locations.remove(corr);
    _log.fine('applied success via registry for correlation=$corr');
    return true;
  }

  bool _applyToController(
    FormFieldsMyImageController controller,
    _PersistedRef ref,
    _UploadResult result,
  ) {
    final images = controller.images.toList();
    if (!_applySuccess(images, ref, result)) return false;
    controller.setImages(images);
    return true;
  }

  bool _applyToProvider(
    FormFieldsMyImageProvider provider,
    _PersistedRef ref,
    _UploadResult result,
  ) {
    final images = provider.images.toList();
    if (!_applySuccess(images, ref, result)) return false;
    provider.setImages(images);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Pending buffer
  // ---------------------------------------------------------------------------

  void _tryApplyPendingToController(FormFieldsMyImageController controller) {
    _drainPending(
      (pending) => _applyToController(controller, pending.ref, pending.result),
    );
  }

  void _tryApplyPendingToProvider(FormFieldsMyImageProvider provider) {
    _drainPending((pending) {
      final applied = _applyToProvider(provider, pending.ref, pending.result);
      if (applied) {
        final corr = pending.ref.correlationId;
        if (corr != null) _locations.remove(corr);
      }
      return applied;
    });
  }

  /// Tries [tryApply] on every buffered success and drops the ones it applied.
  void _drainPending(bool Function(_PendingSuccess) tryApply) {
    if (_pending.isEmpty || _draining) return;
    _draining = true;
    var changed = false;
    try {
      changed = _prunePending() > 0;
      // Iterate over a snapshot: applying may notify listeners.
      for (final pending in List<_PendingSuccess>.of(_pending)) {
        if (tryApply(pending)) {
          _pending.remove(pending);
          changed = true;
          _log.fine('applied pending success; remaining=${_pending.length}');
        }
      }
    } catch (e, st) {
      _log.warning('applying pending success failed', e, st);
    } finally {
      _draining = false;
      if (changed) _persistPending();
    }
  }

  /// Number of successes waiting for a matching image. Intended for tests and
  /// diagnostics.
  @visibleForTesting
  int get pendingCount => _pending.length;

  /// Completes once every persisted write queued so far has finished. Tests
  /// only.
  @visibleForTesting
  Future<void> get pendingWritesFlushed =>
      _store?.flushed ?? Future<void>.value();

  /// Clears all buffered state and detaches the durable store. Tests only.
  @visibleForTesting
  void resetForTesting() {
    _pending.clear();
    _locations.clear();
    _store = null;
  }

  /// Adds [entry]. A retried upload with the same correlation id supersedes
  /// the older entry instead of accumulating duplicates.
  void _insertPending(_PendingSuccess entry) {
    final corr = entry.ref.correlationId;
    if (corr != null) {
      _pending.removeWhere((e) => e.ref.correlationId == corr);
    }
    _pending.add(entry);
  }

  /// Drops entries older than [_pendingTtl]. Returns the number removed.
  int _prunePending() {
    final now = DateTime.now();
    final before = _pending.length;
    _pending.removeWhere((e) => now.difference(e.createdAt) >= _pendingTtl);
    final removed = before - _pending.length;
    if (removed > 0) {
      _log.info('discarded $removed expired pending success(es)');
    }
    return removed;
  }

  /// Keeps at most [_maxPending] entries, dropping the oldest first.
  void _trimPending() {
    _prunePending();
    final overflow = _pending.length - _maxPending;
    if (overflow > 0) {
      _pending.removeRange(0, overflow);
      _log.warning('pending buffer full; dropped $overflow oldest success(es)');
    }
  }

  /// Writes the buffer to the durable store, when one is configured.
  Future<void> _persistPending() {
    final store = _store;
    if (store == null) return Future<void>.value();
    final records = <Map<String, dynamic>>[
      for (final entry in _pending) ?entry.toJson(),
    ];
    return store.write(records);
  }

  // ---------------------------------------------------------------------------
  // Matching helpers (shared by every apply path)
  // ---------------------------------------------------------------------------

  /// Marks every image in [images] that matches [ref] as uploaded. Returns
  /// true when at least one image was changed.
  bool _applySuccess(
    List<MyImageResult> images,
    _PersistedRef ref,
    _UploadResult result,
  ) {
    var updated = false;
    for (var i = 0; i < images.length; i++) {
      if (!ref.matchesStrongly(images[i])) continue;
      images[i] = _markUploaded(images[i], result);
      updated = true;
    }
    if (updated) return true;

    // File-name matching is a last resort, and only the first image is marked.
    // Many images can share a name such as "image.jpg", so marking every match
    // would mark images that were never uploaded.
    for (var i = 0; i < images.length; i++) {
      if (!ref.matchesByFileName(images[i])) continue;
      images[i] = _markUploaded(images[i], result);
      return true;
    }
    return false;
  }

  static MyImageResult _markUploaded(MyImageResult img, _UploadResult result) {
    return MyImageResult(
      link: result.link ?? img.link,
      base64: img.base64,
      path: img.path,
      imageId: result.imageId ?? img.imageId,
      description: img.description,
      payload: img.payload,
      status: MyImageStatus.uploaded,
    );
  }
}

/// Values extracted once from the server response of a successful upload.
class _UploadResult {
  const _UploadResult({this.link, this.imageId});

  factory _UploadResult.from(Map<String, dynamic> persisted, Response resp) {
    return _UploadResult(
      link: UploadResponseMapper.extractUploadedLink(
        resp.data,
        keys: persisted['uploadFileUrlKey']?.toString() ?? 'fileUrl',
      ),
      imageId: UploadResponseMapper.extractImageId(
        resp.data,
        keys: persisted['uploadImageIdKey']?.toString() ?? 'imageId',
      ),
    );
  }

  final String? link;
  final String? imageId;
}

/// Identifying data of a persisted upload, used to find the matching image.
class _PersistedRef {
  const _PersistedRef({
    this.correlationId,
    this.path,
    this.base64,
    this.fileName,
  });

  factory _PersistedRef.from(Map<String, dynamic> persisted) {
    final file = persisted['file'];
    final fileMap = file is Map
        ? Map<String, dynamic>.from(file)
        : const <String, dynamic>{};
    final path = _nonEmpty(fileMap['path']);
    final base64 = _nonEmpty(fileMap['base64']);
    return _PersistedRef(
      correlationId: persisted['uploadCorrelationId']?.toString(),
      path: path,
      base64: base64 == null ? null : _stripDataPrefix(base64),
      fileName:
          _nonEmpty(fileMap['fileName']) ??
          (path == null ? null : p.basename(path)),
    );
  }

  final String? correlationId;
  final String? path;
  final String? base64;
  final String? fileName;

  /// Strong match: same correlation id, file path, or base64 content.
  bool matchesStrongly(MyImageResult img) {
    final imgCorr = img.payload['uploadCorrelationId']?.toString();
    if (correlationId != null && imgCorr != null && correlationId == imgCorr) {
      return true;
    }

    final imgPath = _nonEmpty(img.path);
    if (path != null && imgPath != null && path == imgPath) return true;

    final imgBase64 = _nonEmpty(img.base64);
    return base64 != null &&
        imgBase64 != null &&
        base64 == _stripDataPrefix(imgBase64);
  }

  /// Weak match: same file name. Several images can share a name, so callers
  /// must use this only as a fallback.
  bool matchesByFileName(MyImageResult img) {
    if (fileName == null) return false;
    final imgPath = _nonEmpty(img.path);
    final imgFileName = imgPath != null
        ? p.basename(imgPath)
        : _nonEmpty(_fileMapOf(img)?['fileName']);
    return imgFileName != null && fileName == imgFileName;
  }

  static Map<String, dynamic>? _fileMapOf(MyImageResult img) {
    final file = img.payload['file'];
    return file is Map ? Map<String, dynamic>.from(file) : null;
  }
}

class _PendingSuccess {
  _PendingSuccess({
    required this.persisted,
    required this.result,
    required this.createdAt,
  }) : ref = _PersistedRef.from(persisted);

  /// Restores an entry from [toJson] output. Returns null for malformed data.
  static _PendingSuccess? fromJson(Map<String, dynamic> json) {
    try {
      final persisted = json['persisted'];
      final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
      if (persisted is! Map || createdAt == null) return null;
      return _PendingSuccess(
        persisted: Map<String, dynamic>.from(persisted),
        result: _UploadResult(
          link: json['link'] as String?,
          imageId: json['imageId'] as String?,
        ),
        createdAt: createdAt,
      );
    } catch (e, st) {
      _log.warning('Skipping malformed pending upload record', e, st);
      return null;
    }
  }

  /// JSON form of this entry, or null when [persisted] cannot be encoded
  /// (such an entry stays in memory only).
  Map<String, dynamic>? toJson() => _json;

  /// Encoded once: the whole buffer is re-persisted on every change, and
  /// [persisted] can hold large base64 payloads.
  late final Map<String, dynamic>? _json = _encodeOnce();

  Map<String, dynamic>? _encodeOnce() {
    try {
      jsonEncode(persisted);
    } catch (_) {
      return null;
    }
    return {
      'persisted': persisted,
      'link': result.link,
      'imageId': result.imageId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  final Map<String, dynamic> persisted;
  final _PersistedRef ref;
  final _UploadResult result;
  final DateTime createdAt;
}

class _ImageLocation {
  const _ImageLocation(this.provider, this.index);

  final FormFieldsMyImageProvider provider;
  final int index;
}

String? _nonEmpty(Object? value) {
  if (value is! String) return null;
  return value.trim().isEmpty ? null : value;
}

/// Removes a leading `data:<mime>;base64,` prefix, if present.
String _stripDataPrefix(String s) {
  if (!s.startsWith('data:')) return s;
  final comma = s.indexOf(',');
  return comma >= 0 ? s.substring(comma + 1) : s;
}
