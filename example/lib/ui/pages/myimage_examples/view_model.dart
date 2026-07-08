import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

import 'package:form_fields_example/data/models/product.dart';
import 'package:form_fields/form_fields.dart';

class ViewModel extends ChangeNotifier {
  String autocompleteCustomQueryParamResult = '';
  String autocompleteTokenResult = '';
  String autocompleteCustomResultProcessorResult = '';
  String autocompleteCustomDecorationResult = '';
  String string1 = '';
  String? string2;
  String stringCustom = '';
  String email = '';

  final formKey = GlobalKey<FormState>();
  final focusNode1 = FocusNode();
  final focusNode2 = FocusNode();

  String phone = '';
  String phoneWithCountryCode = '';
  String phoneFormatted = '';
  String password = '';
  String verificationCode = '';
  String verificationCodeNoOtp = '';
  String verificationCodeHiddenOtp = '';
  String verificationCodeHiddenSingle = '';
  String verificationCodeStyled = '';
  String otp4Code = '';

  int int1 = 0;
  int? int2;

  double double1 = 0.0;
  double? double2;

  DateTime date1 = DateTime.now();
  DateTime? date2;

  TimeOfDay time1 = TimeOfDay.now();
  TimeOfDay? time2;

  DateTimeRange range1 =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());
  DateTimeRange? range2;
  // For Product autocomplete demo
  Product? selectedProduct;

  void updateSelectedProduct(Product? value) {
    selectedProduct = value;
    notifyListeners();
  }

  void updateString1(String value) {
    string1 = value;
    notifyListeners();
  }

  void updateString2(String? value) {
    string2 = value;
    notifyListeners();
  }

  void updateStringCustom(String value) {
    stringCustom = value;
    notifyListeners();
  }

  void updateEmail(String value) {
    email = value;
    notifyListeners();
  }

  void updatePhone(String value) {
    phone = value;
    notifyListeners();
  }

  void updatePhoneWithCountryCode(String value) {
    phoneWithCountryCode = value;
    notifyListeners();
  }

  void updatePhoneFormatted(String value) {
    phoneFormatted = value;
    notifyListeners();
  }

  void updatePassword(String value) {
    password = value;
    notifyListeners();
  }

  void updateVerificationCode(String value) {
    verificationCode = value;
    notifyListeners();
  }

  void updateVerificationCodeNoOtp(String value) {
    verificationCodeNoOtp = value;
    notifyListeners();
  }

  void updateVerificationCodeHiddenOtp(String value) {
    verificationCodeHiddenOtp = value;
    notifyListeners();
  }

  void updateVerificationCodeHiddenSingle(String value) {
    verificationCodeHiddenSingle = value;
    notifyListeners();
  }

  void updateVerificationCodeStyled(String value) {
    verificationCodeStyled = value;
    notifyListeners();
  }

  void updateOtp4Code(String value) {
    otp4Code = value;
    notifyListeners();
  }

  void updateInt1(int value) {
    int1 = value;
    notifyListeners();
  }

  void updateInt2(int? value) {
    int2 = value;
    notifyListeners();
  }

  void updateDouble1(double value) {
    double1 = value;
    notifyListeners();
  }

  void updateDouble2(double? value) {
    double2 = value;
    notifyListeners();
  }

  void updateDate1(DateTime value) {
    date1 = value;
    notifyListeners();
  }

  void updateDate2(DateTime? value) {
    date2 = value;
    notifyListeners();
  }

  void updateTime1(TimeOfDay value) {
    time1 = value;
    notifyListeners();
  }

  void updateTime2(TimeOfDay? value) {
    time2 = value;
    notifyListeners();
  }

  void updateRange1(DateTimeRange value) {
    range1 = value;
    notifyListeners();
  }

  void updateRange2(DateTimeRange? value) {
    range2 = value;
    notifyListeners();
  }

  @override
  void dispose() {
    focusNode1.dispose();
    focusNode2.dispose();
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
    try {
      final file = File(
          '${Directory.systemTemp.path}/form_fields_offline_payloads_myimage.json');
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

      // Debug: report incoming payloads
      try {
        if (kDebugMode) {
          print('handleDirectUploadPayload: incoming=${payloads.length}');
        }
      } catch (_) {}

      // Append new payloads but avoid duplicates. We consider a payload
      // duplicate if an existing persisted entry has the same file.base64
      // or matching uploadCorrelationId. Also avoid adding duplicate
      // in-memory previews.
      for (final payload in payloads) {
        try {
          // Normalize flat payload shapes into canonical nested form
          final normalized = Map<String, dynamic>.from(payload);
          try {
            // Tag payload with source so example pages can share a single
            // persisted file without mixing each other's previews.
            normalized['source'] = 'myimage';
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

          // Ensure persisted payloads carry a correlation id so the
          // OfflineUploadManager can reliably match retries back to
          // controller/provider images when the upload succeeds.
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
                // If both have correlation ids and they match, it's a dup
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
                  final existingBase64 = existingFile['base64'] is String
                      ? existingFile['base64'] as String
                      : null;
                  // Only treat as duplicate when both sides have base64 and they match.
                  // Avoid deduping purely by path since some pickers may reuse
                  // temporary file paths across picks.
                  if (pBase64 != null &&
                      existingBase64 != null &&
                      existingBase64 == pBase64) {
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

          // Append the normalized payload to persisted list so it
          // carries the canonical shape and the generated
          // `uploadCorrelationId`. Using the original `payload`
          // could omit the correlation id and produce inconsistent
          // persisted entries (possible duplicates / matching issues).
          arr.add(normalized);
          try {
            if (kDebugMode) {
              print(
                  'handleDirectUploadPayload: appended uploadCorrelationId=${normalized['uploadCorrelationId']} path=${normalized['file'] is Map ? normalized['file']['path'] : ''} hasBase64=${normalized['file'] is Map && (normalized['file']['base64'] ?? '').toString().isNotEmpty}');
            }
          } catch (_) {}

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
      // Only count entries relevant to this view (myimage) when
      // showing the offline queue in this page.
      _offlineQueueCount = arr
          .where((e) =>
              e is Map && (e['source'] == null || e['source'] == 'myimage'))
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
          '${Directory.systemTemp.path}/form_fields_offline_payloads_myimage.json');
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

          // Build upload payload for inspection before attempting
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
            '${Directory.systemTemp.path}/form_fields_offline_payloads_myimage.json');
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
          if (src != null && src != 'myimage') continue;
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
