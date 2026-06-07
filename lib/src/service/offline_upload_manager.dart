import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:form_fields/src/controllers/form_fields_my_image_controller.dart';
import 'package:form_fields/src/providers/form_fields_my_image_provider.dart';
import 'package:form_fields/src/utilities/myimage_result.dart';
import 'package:form_fields/src/utilities/enums.dart';
import 'package:form_fields/src/utilities/upload_response_mapper.dart';

/// Simple manager that keeps registered `FormFieldsMyImageController` instances
/// and updates matching images when a persisted/offline upload succeeds.
class OfflineUploadManager {
  OfflineUploadManager._();

  static final OfflineUploadManager instance = OfflineUploadManager._();

  final Set<FormFieldsMyImageController> _controllers =
      <FormFieldsMyImageController>{};
  final Map<FormFieldsMyImageController, VoidCallback> _listeners =
      <FormFieldsMyImageController, VoidCallback>{};

  final List<_PendingSuccess> _pending = <_PendingSuccess>[];
  final Set<FormFieldsMyImageProvider> _providers =
      <FormFieldsMyImageProvider>{};
  final Map<FormFieldsMyImageProvider, VoidCallback> _providerListeners =
      <FormFieldsMyImageProvider, VoidCallback>{};
  final Map<String, _ImageLocation> _locations = <String, _ImageLocation>{};

  static const _pendingTtlHours = 24;

  void registerController(FormFieldsMyImageController controller) {
    _controllers.add(controller);
    // add change listener so we can try to apply pending successes when
    // controller images change (e.g., widgets finished mounting).
    void listener() {
      _tryApplyPendingToController(controller);
    }

    controller.addListener(listener);
    _listeners[controller] = listener;

    debugPrint(
        'OfflineUploadManager: registerController total=${_controllers.length}');

    // Immediately try to apply any pending successes to the newly
    // registered controller.
    _tryApplyPendingToController(controller);
  }

  void registerProvider(FormFieldsMyImageProvider provider) {
    if (_providers.contains(provider)) return;
    _providers.add(provider);
    void listener() {
      _tryApplyPendingToProvider(provider);
    }

    provider.addListener(listener);
    _providerListeners[provider] = listener;
    debugPrint(
        'OfflineUploadManager: registerProvider total=${_providers.length}');
    _tryApplyPendingToProvider(provider);
    // Update registry for quick correlation-id based matching.
    updateProviderLocations(provider, provider.images);
  }

  void unregisterController(FormFieldsMyImageController controller) {
    final l = _listeners.remove(controller);
    if (l != null) controller.removeListener(l);
    _controllers.remove(controller);
    debugPrint(
        'OfflineUploadManager: unregisterController total=${_controllers.length}');
  }

  void unregisterProvider(FormFieldsMyImageProvider provider) {
    final l = _providerListeners.remove(provider);
    if (l != null) provider.removeListener(l);
    _providers.remove(provider);
    debugPrint(
        'OfflineUploadManager: unregisterProvider total=${_providers.length}');
    // Clean up any registry entries for this provider
    _locations.removeWhere((_, loc) => loc.provider == provider);
  }

  /// Called when an upload for a persisted payload succeeded. The manager
  /// will try to find any registered controller that contains an image
  /// matching the persisted payload (match by `file.path`, `file.base64` or
  /// filename) and update that image to `MyImageStatus.uploaded` (and fill
  /// link/id when available) so UI indicators update automatically.
  void notifyUploadSuccess(Map<String, dynamic> persisted, Response resp) {
    try {
      final link = UploadResponseMapper.extractUploadedLink(resp.data,
          keys: persisted['uploadFileUrlKey'] ?? 'fileUrl');
      final imageId = UploadResponseMapper.extractImageId(resp.data,
          keys: persisted['uploadImageIdKey'] ?? 'imageId');

      debugPrint(
          'OfflineUploadManager: notifyUploadSuccess link=$link imageId=$imageId controllers=${_controllers.length}');

      var anyMatched = false;

      // Quick path: if persisted payload carries a correlation id and we
      // know a provider+index mapping for it, update that location directly.
      final persistedCorr = persisted['uploadCorrelationId']?.toString();
      if (persistedCorr != null && _locations.containsKey(persistedCorr)) {
        final loc = _locations[persistedCorr]!;
        try {
          final provImages = loc.provider.images.toList();
          if (loc.index >= 0 && loc.index < provImages.length) {
            final img = provImages[loc.index];
            provImages[loc.index] = MyImageResult(
              link: link ?? img.link,
              base64: img.base64,
              path: img.path,
              imageId: imageId ?? img.imageId,
              description: img.description,
              payload: img.payload,
              status: MyImageStatus.uploaded,
            );
            loc.provider.setImages(provImages);
            _locations.remove(persistedCorr);
            anyMatched = true;
            debugPrint(
                'OfflineUploadManager: applied success via registry for correlation=$persistedCorr');
          }
        } catch (_) {}
      }

      for (final controller in _controllers) {
        final images = controller.images.toList();
        var updated = false;

        debugPrint(
            'OfflineUploadManager: checking controller with images=${images.length}');

        // Pre-extract persisted file info once per controller
        final fileMap = persisted['file'] is Map
            ? Map<String, dynamic>.from(persisted['file'] as Map)
            : <String, dynamic>{};
        final pPath = fileMap['path'] is String &&
                (fileMap['path'] as String).trim().isNotEmpty
            ? fileMap['path'] as String
            : null;
        final pBase64 = fileMap['base64'] is String &&
                (fileMap['base64'] as String).trim().isNotEmpty
            ? fileMap['base64'] as String
            : null;
        final pFileName = fileMap['fileName'] is String &&
                (fileMap['fileName'] as String).trim().isNotEmpty
            ? fileMap['fileName'] as String
            : (pPath?.split(Platform.pathSeparator).last);
        final pCorr = persisted['uploadCorrelationId']?.toString();

        String stripDataPrefix(String s) {
          if (s.startsWith('data:')) {
            final comma = s.indexOf(',');
            if (comma >= 0) return s.substring(comma + 1);
          }
          return s;
        }

        for (var i = 0; i < images.length; i++) {
          final img = images[i];
          // If both persisted payload and controller image carry a
          // correlation id, match by it first — it's the most reliable
          // method to identify the same logical upload.
          final imgCorr = img.payload['uploadCorrelationId']?.toString();
          if (pCorr != null && imgCorr != null && pCorr == imgCorr) {
            debugPrint(
                'OfflineUploadManager: matched controller image idx=$i by correlationId=$pCorr');
            images[i] = MyImageResult(
              link: link ?? img.link,
              base64: img.base64,
              path: img.path,
              imageId: imageId ?? img.imageId,
              description: img.description,
              payload: img.payload,
              status: MyImageStatus.uploaded,
            );
            updated = true;
            continue;
          }
          final imgPath = img.path.isNotEmpty ? img.path : null;
          final imgBase64 = img.base64.isNotEmpty ? img.base64 : null;
          final imgFileName = imgPath != null
              ? imgPath.split(Platform.pathSeparator).last
              : (img.payload['file'] is Map
                  ? (img.payload['file']['fileName'] is String
                      ? img.payload['file']['fileName'] as String
                      : null)
                  : null);

          final matchesPath =
              (pPath != null && imgPath != null && pPath == imgPath);
          final matchesBase64 = (pBase64 != null &&
              imgBase64 != null &&
              stripDataPrefix(pBase64) == stripDataPrefix(imgBase64));
          final matchesFileName = (pFileName != null &&
              imgFileName != null &&
              pFileName == imgFileName);

          if (matchesPath || matchesBase64 || matchesFileName) {
            debugPrint(
                'OfflineUploadManager: matched controller image idx=$i path=${img.path} imageId=${img.imageId} (by ${matchesPath ? 'path' : matchesBase64 ? 'base64' : 'fileName'})');
            images[i] = MyImageResult(
              link: link ?? img.link,
              base64: img.base64,
              path: img.path,
              imageId: imageId ?? img.imageId,
              description: img.description,
              payload: img.payload,
              status: MyImageStatus.uploaded,
            );
            updated = true;
          }
        }

        if (updated) {
          anyMatched = true;
          debugPrint(
              'OfflineUploadManager: updating controller with ${images.length} images');
          controller.setImages(images);
        }
      }
      // If no currently-registered controller matched this persisted
      // payload, try providers; if still no match, keep it in a small
      // pending buffer and try again when controllers/providers change.
      if (!anyMatched) {
        // attempt to match providers immediately
        for (final provider in _providers) {
          final provImages = provider.images.toList();
          var provUpdated = false;

          // Pre-extract persisted file info once per provider
          final fileMap = persisted['file'] is Map
              ? Map<String, dynamic>.from(persisted['file'] as Map)
              : <String, dynamic>{};
          final pPath = fileMap['path'] is String &&
                  (fileMap['path'] as String).trim().isNotEmpty
              ? fileMap['path'] as String
              : null;
          final pBase64 = fileMap['base64'] is String &&
                  (fileMap['base64'] as String).trim().isNotEmpty
              ? fileMap['base64'] as String
              : null;
          final pFileName = fileMap['fileName'] is String &&
                  (fileMap['fileName'] as String).trim().isNotEmpty
              ? fileMap['fileName'] as String
              : (pPath?.split(Platform.pathSeparator).last);
          final pCorr = persisted['uploadCorrelationId']?.toString();

          String stripDataPrefix(String s) {
            if (s.startsWith('data:')) {
              final comma = s.indexOf(',');
              if (comma >= 0) return s.substring(comma + 1);
            }
            return s;
          }

          for (var i = 0; i < provImages.length; i++) {
            final img = provImages[i];
            final imgCorr = img.payload['uploadCorrelationId']?.toString();
            if (pCorr != null && imgCorr != null && pCorr == imgCorr) {
              provImages[i] = MyImageResult(
                link: link ?? img.link,
                base64: img.base64,
                path: img.path,
                imageId: imageId ?? img.imageId,
                description: img.description,
                payload: img.payload,
                status: MyImageStatus.uploaded,
              );
              provUpdated = true;
              continue;
            }
            final imgPath = img.path.isNotEmpty ? img.path : null;
            final imgBase64 = img.base64.isNotEmpty ? img.base64 : null;
            final imgFileName = imgPath != null
                ? imgPath.split(Platform.pathSeparator).last
                : (img.payload['file'] is Map
                    ? (img.payload['file']['fileName'] is String
                        ? img.payload['file']['fileName'] as String
                        : null)
                    : null);

            final matchesPath =
                (pPath != null && imgPath != null && pPath == imgPath);
            final matchesBase64 = (pBase64 != null &&
                imgBase64 != null &&
                stripDataPrefix(pBase64) == stripDataPrefix(imgBase64));
            final matchesFileName = (pFileName != null &&
                imgFileName != null &&
                pFileName == imgFileName);

            if (matchesPath || matchesBase64 || matchesFileName) {
              provImages[i] = MyImageResult(
                link: link ?? img.link,
                base64: img.base64,
                path: img.path,
                imageId: imageId ?? img.imageId,
                description: img.description,
                payload: img.payload,
                status: MyImageStatus.uploaded,
              );
              provUpdated = true;
            }
          }

          if (provUpdated) {
            anyMatched = true;
            debugPrint(
                'OfflineUploadManager: updating provider with ${provImages.length} images');
            provider.setImages(provImages);
          }
        }
      }

      if (!anyMatched) {
        _pending.add(_PendingSuccess(persisted, resp, DateTime.now()));
        _prunePending();
        debugPrint(
            'OfflineUploadManager: queued pending success (${_pending.length})');
      }
    } catch (e, st) {
      debugPrint('OfflineUploadManager: notifyUploadSuccess error: $e\n$st');
      // best-effort: ignore errors
    }
  }

  void _tryApplyPendingToController(FormFieldsMyImageController controller) {
    if (_pending.isEmpty) return;
    try {
      // Iterate over a copy because we may remove matched entries.
      final copy = List<_PendingSuccess>.from(_pending);
      for (final p in copy) {
        final persisted = p.persisted;
        final resp = p.resp;
        final link = UploadResponseMapper.extractUploadedLink(resp.data,
            keys: persisted['uploadFileUrlKey'] ?? 'fileUrl');
        final imageId = UploadResponseMapper.extractImageId(resp.data,
            keys: persisted['uploadImageIdKey'] ?? 'imageId');

        final images = controller.images.toList();
        var updated = false;

        // Pre-extract persisted file info once per controller
        final fileMap = persisted['file'] is Map
            ? Map<String, dynamic>.from(persisted['file'] as Map)
            : <String, dynamic>{};
        final pPath = fileMap['path'] is String &&
                (fileMap['path'] as String).trim().isNotEmpty
            ? fileMap['path'] as String
            : null;
        final pBase64 = fileMap['base64'] is String &&
                (fileMap['base64'] as String).trim().isNotEmpty
            ? fileMap['base64'] as String
            : null;
        final pFileName = fileMap['fileName'] is String &&
                (fileMap['fileName'] as String).trim().isNotEmpty
            ? fileMap['fileName'] as String
            : (pPath?.split(Platform.pathSeparator).last);
        final pCorr = persisted['uploadCorrelationId']?.toString();

        String stripDataPrefix(String s) {
          if (s.startsWith('data:')) {
            final comma = s.indexOf(',');
            if (comma >= 0) return s.substring(comma + 1);
          }
          return s;
        }

        for (var i = 0; i < images.length; i++) {
          final img = images[i];
          final imgCorr = img.payload['uploadCorrelationId']?.toString();
          if (pCorr != null && imgCorr != null && pCorr == imgCorr) {
            images[i] = MyImageResult(
              link: link ?? img.link,
              base64: img.base64,
              path: img.path,
              imageId: imageId ?? img.imageId,
              description: img.description,
              payload: img.payload,
              status: MyImageStatus.uploaded,
            );
            updated = true;
            continue;
          }

          final imgPath = img.path.isNotEmpty ? img.path : null;
          final imgBase64 = img.base64.isNotEmpty ? img.base64 : null;
          final imgFileName = imgPath != null
              ? imgPath.split(Platform.pathSeparator).last
              : (img.payload['file'] is Map
                  ? (img.payload['file']['fileName'] is String
                      ? img.payload['file']['fileName'] as String
                      : null)
                  : null);

          final matchesPath =
              (pPath != null && imgPath != null && pPath == imgPath);
          final matchesBase64 = (pBase64 != null &&
              imgBase64 != null &&
              stripDataPrefix(pBase64) == stripDataPrefix(imgBase64));
          final matchesFileName = (pFileName != null &&
              imgFileName != null &&
              pFileName == imgFileName);

          if (matchesPath || matchesBase64 || matchesFileName) {
            images[i] = MyImageResult(
              link: link ?? img.link,
              base64: img.base64,
              path: img.path,
              imageId: imageId ?? img.imageId,
              description: img.description,
              payload: img.payload,
              status: MyImageStatus.uploaded,
            );
            updated = true;
          }
        }

        if (updated) {
          controller.setImages(images);
          _pending.remove(p);
          debugPrint(
              'OfflineUploadManager: applied pending success to controller; remaining=${_pending.length}');
        }
      }
    } catch (e, st) {
      debugPrint(
          'OfflineUploadManager: _tryApplyPendingToController error: $e\n$st');
    }
  }

  void _tryApplyPendingToProvider(FormFieldsMyImageProvider provider) {
    if (_pending.isEmpty) return;
    try {
      final copy = List<_PendingSuccess>.from(_pending);
      for (final p in copy) {
        final persisted = p.persisted;
        final resp = p.resp;
        final link = UploadResponseMapper.extractUploadedLink(resp.data,
            keys: persisted['uploadFileUrlKey'] ?? 'fileUrl');
        final imageId = UploadResponseMapper.extractImageId(resp.data,
            keys: persisted['uploadImageIdKey'] ?? 'imageId');

        final images = provider.images.toList();
        var updated = false;

        // Pre-extract persisted file info once per provider
        final fileMap = persisted['file'] is Map
            ? Map<String, dynamic>.from(persisted['file'] as Map)
            : <String, dynamic>{};
        final pPath = fileMap['path'] is String &&
                (fileMap['path'] as String).trim().isNotEmpty
            ? fileMap['path'] as String
            : null;
        final pBase64 = fileMap['base64'] is String &&
                (fileMap['base64'] as String).trim().isNotEmpty
            ? fileMap['base64'] as String
            : null;
        final pFileName = fileMap['fileName'] is String &&
                (fileMap['fileName'] as String).trim().isNotEmpty
            ? fileMap['fileName'] as String
            : (pPath?.split(Platform.pathSeparator).last);
        final pCorr = persisted['uploadCorrelationId']?.toString();

        String stripDataPrefix(String s) {
          if (s.startsWith('data:')) {
            final comma = s.indexOf(',');
            if (comma >= 0) return s.substring(comma + 1);
          }
          return s;
        }

        for (var i = 0; i < images.length; i++) {
          final img = images[i];
          final imgCorr = img.payload['uploadCorrelationId']?.toString();
          if (pCorr != null && imgCorr != null && pCorr == imgCorr) {
            images[i] = MyImageResult(
              link: link ?? img.link,
              base64: img.base64,
              path: img.path,
              imageId: imageId ?? img.imageId,
              description: img.description,
              payload: img.payload,
              status: MyImageStatus.uploaded,
            );
            updated = true;
            continue;
          }

          final imgPath = img.path.isNotEmpty ? img.path : null;
          final imgBase64 = img.base64.isNotEmpty ? img.base64 : null;
          final imgFileName = imgPath != null
              ? imgPath.split(Platform.pathSeparator).last
              : (img.payload['file'] is Map
                  ? (img.payload['file']['fileName'] is String
                      ? img.payload['file']['fileName'] as String
                      : null)
                  : null);

          final matchesPath =
              (pPath != null && imgPath != null && pPath == imgPath);
          final matchesBase64 = (pBase64 != null &&
              imgBase64 != null &&
              stripDataPrefix(pBase64) == stripDataPrefix(imgBase64));
          final matchesFileName = (pFileName != null &&
              imgFileName != null &&
              pFileName == imgFileName);

          if (matchesPath || matchesBase64 || matchesFileName) {
            images[i] = MyImageResult(
              link: link ?? img.link,
              base64: img.base64,
              path: img.path,
              imageId: imageId ?? img.imageId,
              description: img.description,
              payload: img.payload,
              status: MyImageStatus.uploaded,
            );
            updated = true;
          }
        }

        if (updated) {
          provider.setImages(images);
          _pending.remove(p);
          debugPrint(
              'OfflineUploadManager: applied pending success to provider; remaining=${_pending.length}');
          // remove any registry entries for this persisted payload
          final corr = p.persisted['uploadCorrelationId']?.toString();
          if (corr != null) _locations.remove(corr);
        }
      }
    } catch (e, st) {
      debugPrint(
          'OfflineUploadManager: _tryApplyPendingToProvider error: $e\n$st');
    }
  }

  void _prunePending() {
    final now = DateTime.now();
    _pending.removeWhere(
        (p) => now.difference(p.createdAt).inHours >= _pendingTtlHours);
  }

  /// Update registry of correlation id -> provider+index locations.
  void updateProviderLocations(
      FormFieldsMyImageProvider provider, List<MyImageResult> images) {
    // Remove existing entries for this provider
    _locations.removeWhere((_, loc) => loc.provider == provider);
    for (var i = 0; i < images.length; i++) {
      try {
        final p = images[i].payload;
        if (p['uploadCorrelationId'] != null) {
          final corr = p['uploadCorrelationId'].toString();
          _locations[corr] = _ImageLocation(provider, i);
        }
      } catch (_) {}
    }
  }
}

class _PendingSuccess {
  final Map<String, dynamic> persisted;
  final Response resp;
  final DateTime createdAt;

  _PendingSuccess(this.persisted, this.resp, this.createdAt);
}

class _ImageLocation {
  final FormFieldsMyImageProvider provider;
  final int index;

  _ImageLocation(this.provider, this.index);
}
