import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:form_fields/form_fields.dart';

class ViewModel extends ChangeNotifier {
  // ── Basic example ────────────────────────────────────────────────────────
  final FormFieldsSignaturePadController basicSignatureController =
      FormFieldsSignaturePadController();
  MyImageResult? signatureResult;

  void setSignature(MyImageResult? result) {
    signatureResult = result;
    notifyListeners();
  }

  // ── Live camera example ──────────────────────────────────────────────────
  /// External camera controller so the host page can read the captured photo.
  final FormFieldsMyImageController liveCameraController =
      FormFieldsMyImageController();
  final FormFieldsMyImageController prefilledLiveCameraController =
      FormFieldsMyImageController.fromImages([
    MyImageResult(link: 'https://picsum.photos/seed/live-prefill/800/600'),
  ]);
  final FormFieldsMyImageController standaloneCameraController =
      FormFieldsMyImageController();
  final FormFieldsMyImageController controllerCaptureController =
      FormFieldsMyImageController();

  MyImageResult? controllerCaptureResult;

  void setControllerCapture(MyImageResult? captured) {
    controllerCaptureResult = captured;
    notifyListeners();
  }

  SignaturePadExportResult? exportResult;
  SignaturePadExportResult? prefilledExportResult;
  MyImageResult? liveCaptureResult;
  MyImageResult? standaloneCaptureResult;

  void setExportResult(SignaturePadExportResult result) {
    exportResult = result;
    notifyListeners();
  }

  void setPrefilledExportResult(SignaturePadExportResult result) {
    prefilledExportResult = result;
    notifyListeners();
  }

  void setLiveCapture(MyImageResult captured) {
    liveCaptureResult = captured;
    notifyListeners();
  }

  void setStandaloneCapture(MyImageResult? captured) {
    standaloneCaptureResult = captured;
    notifyListeners();
  }

  // ── Prefilled signature example ──────────────────────────────────────────
  final FormFieldsSignaturePadController prefilledSignatureController =
      FormFieldsSignaturePadController.fromSignature(
    MyImageResult.network(
        'https://picsum.photos/seed/signature-prefill/400/160'),
  );
  SignaturePadExportResult? prefilledSignatureExportResult;

  void setPrefilledSignatureExportResult(SignaturePadExportResult result) {
    prefilledSignatureExportResult = result;
    notifyListeners();
  }

  // ── Prefilled signature + live camera example ────────────────────────────
  final FormFieldsSignaturePadController prefilledBothController =
      FormFieldsSignaturePadController.fromExportResult(
    SignaturePadExportResult(
      signature:
          MyImageResult(link: 'https://picsum.photos/seed/sig-both/400/160'),
      liveCapture: MyImageResult.network(
          'https://picsum.photos/seed/prefill-both/800/600'),
    ),
  );
  SignaturePadExportResult? prefilledBothExportResult;

  void setPrefilledBothExportResult(SignaturePadExportResult result) {
    prefilledBothExportResult = result;
    notifyListeners();
  }

  // ── Direct upload examples ───────────────────────────────────────────────
  final FormFieldsSignaturePadController uploadedSignatureController =
      FormFieldsSignaturePadController();
  MyImageResult? uploadedSignatureResult;
  SignaturePadExportResult? uploadedExportResult;

  void setUploadedSignature(MyImageResult? result) {
    uploadedSignatureResult = result;
    notifyListeners();
  }

  void setUploadedExportResult(SignaturePadExportResult result) {
    uploadedExportResult = result;
    notifyListeners();
  }

  // ── Silent live capture example ──────────────────────────────────────────
  MyImageResult? silentCaptureResult;
  SignaturePadExportResult? silentExportResult;

  void setSilentCapture(MyImageResult captured) {
    silentCaptureResult = captured;
    notifyListeners();
  }

  void setSilentExportResult(SignaturePadExportResult result) {
    silentExportResult = result;
    notifyListeners();
  }

  // ── Hidden live camera (FormFieldsLiveCameraCapture hidePreview) ────────
  final FormFieldsMyImageController hiddenLiveCameraController =
      FormFieldsMyImageController();
  MyImageResult? hiddenCaptureResult;

  void setHiddenCapture(MyImageResult captured) {
    hiddenCaptureResult = captured;
    notifyListeners();
  }

  void clearHiddenCapture() {
    hiddenCaptureResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    basicSignatureController.dispose();
    liveCameraController.dispose();
    prefilledLiveCameraController.dispose();
    prefilledSignatureController.dispose();
    prefilledBothController.dispose();
    uploadedSignatureController.dispose();
    standaloneCameraController.dispose();
    controllerCaptureController.dispose();
    hiddenLiveCameraController.dispose();
    super.dispose();
  }

  // ── Offline upload queue (example implementation) ────────────────
  int _offlineQueueCount = 0;

  int get offlineQueueCount => _offlineQueueCount;
  // Simple in-memory preview store for queued offline payloads.
  final List<OfflinePreview> _offlinePreviews = [];
  List<OfflinePreview> get offlinePreviews =>
      List.unmodifiable(_offlinePreviews);

  Future<void> handleDirectUploadPayload(
      List<Map<String, dynamic>> payloads) async {
    if (kDebugMode) {
      debugPrint(
          'ViewModel.handleDirectUploadPayload: received ${payloads.length} payload(s)');
      if (payloads.isNotEmpty) {
        try {
          debugPrint(
              'ViewModel: first payload keys=${payloads.first.keys.toList()}');
        } catch (_) {}
      }
    }

    try {
      final file = File(
          '${Directory.systemTemp.path}/form_fields_offline_payloads_signature_pad.json');
      List<dynamic> arr = [];
      if (await file.exists()) {
        final s = await file.readAsString();
        if (s.trim().isNotEmpty) {
          try {
            arr = jsonDecode(s);
          } catch (_) {
            arr = [];
          }
        }
      }

      // Append new payloads but avoid duplicates. We consider a payload
      // duplicate if an existing persisted entry has the same file.path
      // or file.base64. Also avoid adding duplicate in-memory previews.
      for (final payload in payloads) {
        try {
          // Tag payload with source so example pages can share a single
          // persisted file without mixing each other's previews.
          final normalized = Map<String, dynamic>.from(payload);
          normalized['source'] = 'signature_pad';
          // Ensure persisted payloads carry a correlation id so the
          // OfflineUploadManager can reliably match retries back to
          // controller/provider images when the upload succeeds.
          // Normalize flat payload shapes into the canonical nested form
          // { 'file': { 'path':..., 'base64':..., 'fileName':... }, ... }
          try {
            if (normalized['file'] is! Map) {
              final topPath = (normalized['filePath'] is String &&
                      (normalized['filePath'] as String).trim().isNotEmpty)
                  ? normalized['filePath'] as String
                  : null;
              final topBase64 = (normalized['base64'] is String &&
                      (normalized['base64'] as String).trim().isNotEmpty)
                  ? normalized['base64'] as String
                  : null;
              final topName = (normalized['fileName'] is String &&
                      (normalized['fileName'] as String).trim().isNotEmpty)
                  ? normalized['fileName'] as String
                  : null;
              if (topPath != null || topBase64 != null || topName != null) {
                final fm = <String, dynamic>{};
                if (topPath != null) fm['path'] = topPath;
                if (topBase64 != null) fm['base64'] = topBase64;
                if (topName != null) fm['fileName'] = topName;
                normalized['file'] = fm;
                normalized.remove('filePath');
                normalized.remove('base64');
                normalized.remove('fileName');
              }
            }
          } catch (_) {}

          if (normalized['uploadCorrelationId'] == null) {
            normalized['uploadCorrelationId'] =
                DateTime.now().microsecondsSinceEpoch.toString();
          }
          final fileMap = (normalized['file'] is Map)
              ? Map<String, dynamic>.from(normalized['file'])
              : <String, dynamic>{};
          final pPath = (fileMap['path'] is String &&
                  (fileMap['path'] as String).trim().isNotEmpty)
              ? fileMap['path'] as String
              : null;
          final pBase64 = (fileMap['base64'] is String &&
                  (fileMap['base64'] as String).trim().isNotEmpty)
              ? fileMap['base64'] as String
              : null;

          // Check persisted array for duplicates. Prefer matching by
          // `uploadCorrelationId` when available, otherwise fallback to
          // path/base64 comparisons.
          var alreadyPersisted = false;
          for (final existing in arr) {
            try {
              if (existing is Map) {
                final existingCorr = existing['uploadCorrelationId'];
                if (existingCorr != null &&
                    normalized['uploadCorrelationId'] != null) {
                  if (existingCorr.toString() ==
                      normalized['uploadCorrelationId'].toString()) {
                    alreadyPersisted = true;
                    break;
                  }
                }
                final existingFile = existing['file'];
                if (existingFile is Map) {
                  final existingPath = existingFile['path'] is String
                      ? existingFile['path'] as String
                      : null;
                  final existingBase64 = existingFile['base64'] is String
                      ? existingFile['base64'] as String
                      : null;
                  if ((pPath != null && existingPath == pPath) ||
                      (pBase64 != null && existingBase64 == pBase64)) {
                    alreadyPersisted = true;
                    break;
                  }
                }
              }
            } catch (_) {
              // ignore malformed existing entries
            }
          }
          if (alreadyPersisted) continue;

          // Append to persisted list (use normalized shape)
          arr.add(normalized);

          // Also keep a lightweight preview (path/base64) in memory so the UI
          // can immediately show the image that couldn't be uploaded.
          try {
            // Avoid duplicate previews in memory
            final alreadyPreviewed = _offlinePreviews.any((p) {
              if (p.path != null && p.path == pPath) return true;
              if (p.base64 != null && p.base64 == pBase64) return true;
              return false;
            });
            if (!alreadyPreviewed) {
              _offlinePreviews
                  .add(OfflinePreview(path: pPath, base64: pBase64));
            }
          } catch (_) {
            // ignore
          }
        } catch (_) {
          // ignore individual payload errors
        }
      }

      try {
        // Atomic write: write to a temp file in the same directory then
        // rename it over the original. This reduces risk of file
        // corruption if the process is interrupted during write.
        final parent = file.parent;
        final tmp = File(
            '${parent.path}/form_fields_offline_payloads.json.tmp.${DateTime.now().millisecondsSinceEpoch}');
        await tmp.writeAsString(jsonEncode(arr));
        // Rename should be atomic on most platforms when moving within
        // the same filesystem/directory.
        await tmp.rename(file.path);
      } catch (e) {
        // Fallback to best-effort direct write if atomic swap fails.
        try {
          await file.writeAsString(jsonEncode(arr));
        } catch (_) {}
      }
      // Only count entries relevant to this view (signature pad) when
      // showing the offline queue in this page.
      _offlineQueueCount = arr
          .where((e) =>
              e is Map &&
              (e['source'] == null || e['source'] == 'signature_pad'))
          .length;
      notifyListeners();
    } catch (e) {
      // Best-effort for example: log only
      // ignore: avoid_print
      print('Failed to enqueue offline payload: $e');
    }
  }

  /// Attempt to re-upload persisted offline payloads. This reads the
  /// persisted payload file created by [handleDirectUploadPayload], tries
  /// to upload each payload via `DioUtil.uploadFile`, and removes any
  /// successful uploads from the persisted queue.
  Future<void> retryOfflineUploads(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final file = File(
          '${Directory.systemTemp.path}/form_fields_offline_payloads_signature_pad.json');
      if (!await file.exists()) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('No offline payloads found')),
        );
        return;
      }
      final s = await file.readAsString();
      if (s.trim().isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('No offline payloads found')),
        );
        return;
      }

      String? decodeError;
      List<dynamic> arr = [];
      try {
        arr = jsonDecode(s) as List<dynamic>;
      } catch (e) {
        decodeError = e.toString();
        // Attempt to recover from concatenated or malformed JSON by
        // extracting top-level objects. This handles cases where the
        // persisted file contains multiple JSON objects without a
        // surrounding array (common if writes were interrupted).
        try {
          arr = _extractJsonObjects(s);
        } catch (_) {
          arr = [];
        }
      }

      if (arr.isEmpty) {
        // If we couldn't recover any payloads, write a backup copy of the
        // corrupted content plus a small metadata file to help debugging.
        try {
          final backupDir = Directory(
              '${Directory.systemTemp.path}/form_fields_offline_backups');
          if (!await backupDir.exists()) {
            await backupDir.create(recursive: true);
          }
          final ts = DateTime.now().millisecondsSinceEpoch;
          final backupFile = File(
              '${backupDir.path}/form_fields_offline_payloads.corrupt.$ts.json');
          await backupFile.writeAsString(s);

          final meta = {
            'originalPath': file.path,
            'backupPath': backupFile.path,
            'error': decodeError ?? 'unknown',
            'length': s.length,
            'createdAt': DateTime.now().toIso8601String(),
          };
          final metaFile = File(
              '${backupDir.path}/form_fields_offline_payloads.corrupt.$ts.meta.json');
          await metaFile.writeAsString(jsonEncode(meta));

          debugPrint(
              'Saved corrupt offline payload backup: ${backupFile.path}');
        } catch (e) {
          debugPrint('Failed to save corrupt payload backup: $e');
        }

        // Remove the corrupted file so future retries start fresh.
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}

        messenger?.showSnackBar(
          const SnackBar(
              content: Text(
                  'No offline payloads found (file corrupted, backup saved)')),
        );
        return;
      }

      int success = 0;
      final remaining = <dynamic>[];

      int idx = 0;
      for (final raw in arr) {
        idx++;
        try {
          if (raw is! Map<String, dynamic>) {
            debugPrint('Retry #$idx: skipping non-object entry');
            remaining.add(raw);
            continue;
          }
          final persisted = Map<String, dynamic>.from(raw);

          final built = await UploadHelper.buildUploadPayloadFromMap(persisted);
          if (built == null) {
            debugPrint(
                'Retry #$idx: buildUploadPayloadFromMap -> null, will keep');
            remaining.add(persisted);
            continue;
          }
          debugPrint(
              'Retry #$idx: payload prepared url=${built['url']} filePath=${built['filePath']} fileName=${built['fileName']} tempFileCreated=${built['tempFileCreated']}');
          if (built['filePath'] is String &&
              (built['filePath'] as String).isNotEmpty) {
            try {
              final f = File(built['filePath'] as String);
              final exists = await f.exists();
              final len = exists ? await f.length() : -1;
              debugPrint('Retry #$idx: file exists=$exists length=$len');
            } catch (e) {
              debugPrint('Retry #$idx: error stating file: $e');
            }
          }

          final result = await UploadHelper.uploadPersistedPayload(persisted,
              onProgress: (p) {
            debugPrint('Retry #$idx: upload progress=${p.toStringAsFixed(3)}');
          });

          if (result != null && result.status == MyImageStatus.uploaded) {
            success++;
            debugPrint('Retry #$idx: upload succeeded link=${result.link}');
          } else {
            debugPrint('Retry #$idx: upload failed');
            remaining.add(persisted);
          }
        } catch (e, st) {
          debugPrint('Retry #$idx: exception: $e\n$st');
          remaining.add(raw);
        }
      }

      // persist remaining
      try {
        final file = File(
            '${Directory.systemTemp.path}/form_fields_offline_payloads_signature_pad.json');
        await file.writeAsString(jsonEncode(remaining));
      } catch (_) {}

      // rebuild in-memory previews from remaining, but only include
      // entries that belong to this view (or legacy entries without a
      // source tag).
      _offlinePreviews.clear();
      for (final raw in remaining) {
        try {
          if (raw is! Map) continue;
          final src = raw['source'];
          if (src != null && src != 'signature_pad') continue;
          final fileMap = raw['file'] is Map
              ? Map<String, dynamic>.from(raw['file'])
              : <String, dynamic>{};
          final pPath = fileMap['path'] is String &&
                  (fileMap['path'] as String).trim().isNotEmpty
              ? fileMap['path'] as String
              : null;
          final pBase64 = fileMap['base64'] is String &&
                  (fileMap['base64'] as String).trim().isNotEmpty
              ? fileMap['base64'] as String
              : null;
          _offlinePreviews.add(OfflinePreview(path: pPath, base64: pBase64));
        } catch (_) {}
      }

      _offlineQueueCount = _offlinePreviews.length;
      notifyListeners();

      messenger?.showSnackBar(
        SnackBar(
            content: Text(
                '$success uploads succeeded, $_offlineQueueCount remaining')),
      );
    } catch (e) {
      // ignore errors but inform user
      messenger?.showSnackBar(
        SnackBar(content: Text('Retry failed: $e')),
      );
    }
  }

  // Attempt to extract top-level JSON objects from potentially
  // concatenated/malformed content. Returns a list of decoded objects.
  static List<dynamic> _extractJsonObjects(String s) {
    final results = <dynamic>[];
    int depth = 0;
    int? start;
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < s.length; i++) {
      final ch = s[i];

      if (ch == '"' && !escaped) {
        inString = !inString;
      }

      if (!inString) {
        if (ch == '{') {
          if (depth == 0) start = i;
          depth++;
        } else if (ch == '}') {
          depth--;
          if (depth == 0 && start != null) {
            final substr = s.substring(start, i + 1);
            try {
              final decoded = jsonDecode(substr);
              results.add(decoded);
            } catch (_) {
              // ignore individual parse errors
            }
            start = null;
          }
          if (depth < 0) depth = 0;
        }
      }

      if (ch == '\\' && !escaped) {
        escaped = true;
      } else {
        escaped = false;
      }
    }

    return results;
  }
}

class OfflinePreview {
  final String? path;
  final String? base64;
  final DateTime createdAt;

  OfflinePreview({this.path, this.base64}) : createdAt = DateTime.now();
}
