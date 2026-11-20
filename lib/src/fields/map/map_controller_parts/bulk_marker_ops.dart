part of '../map_controller.dart';

/// Internal implementation for [FormFieldsMapController]; the public API delegates here.
class _MapBulkMarkerOps {
  /// Efficiently apply many coordinate-only updates for [id]. Each update
  /// should be a Map with `id` and `pointMetas` (serializable List of maps)
  /// or `lat`/`lon` for single-point markers. Returns true when applied.
  static bool batchUpdateCoordinates(
    String id,
    List<Map<String, dynamic>> updates, {
    bool createMarkerWidgets = true,
    bool useInPlaceMutation = true,
  }) {
    var n = _MapRegistry._getNotifier(id);
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        _MapRegistry.registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return false;

    final shouldBlock = updates.length >= _MapRegistry._autoBlockingThreshold;
    try {
      if (shouldBlock) {
        try {
          _MapRegistry._blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          _MapRegistry.setBlockingLoading(id, true);
        } catch (_) {}
        try {
          // give frame for overlay
          Future.delayed(Duration.zero);
        } catch (_) {}
      }

      try {
        n.batchUpdateCoordinates(
          updates,
          createMarkerWidgets: createMarkerWidgets,
          useInPlaceMutation: useInPlaceMutation,
        );
      } catch (_) {
        // Fallback: apply per-item via updateRawMarkerCoordinates or upsert
        for (final u in updates) {
          try {
            final idv = (u['id'] as String?) ?? '';
            if (idv.isEmpty) continue;
            if (u['pointMetas'] is List) {
              final pms = (u['pointMetas'] as List)
                  .map(
                    (pm) => PointMeta(
                      lat: (pm['lat'] as num).toDouble(),
                      lon: (pm['lon'] as num).toDouble(),
                    ),
                  )
                  .toList(growable: false);
              n.upsertCoordinates(
                idv,
                pms,
                createMarkerWidgets: createMarkerWidgets,
              );
            } else if (u.containsKey('lat') && u.containsKey('lon')) {
              // convert to single-point ShapeMeta and upsert
              final p = PointMeta(
                lat: (u['lat'] as num).toDouble(),
                lon: (u['lon'] as num).toDouble(),
              );
              n.upsertCoordinates(idv, [
                p,
              ], createMarkerWidgets: createMarkerWidgets);
            }
          } catch (_) {}
        }
      }

      return true;
    } finally {
      if (shouldBlock) {
        try {
          _MapRegistry._blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          _MapRegistry._blockingClearTimers[id] = Timer(
            const Duration(milliseconds: 200),
            () {
              try {
                _MapRegistry.setBlockingLoading(id, false);
              } catch (_) {}
              _MapRegistry._blockingClearTimers.remove(id);
            },
          );
        } catch (_) {}
      }
    }
  }

  /// High-level helper: accept a list of `ShapeMeta` and perform inserts
  /// or updates automatically. Consumers can call this with full
  /// `ShapeMeta` objects and the controller will decide whether to append
  /// new entries or patch existing ones (using `batchUpdateCoordinates`).
  /// Returns true when the operation was attempted.
  static Future<bool> processShapeMetaList(
    String id,
    List<ShapeMeta> shapes, {
    bool createMarkerWidgets = true,
    bool useInPlaceMutation = true,
  }) async {
    if (shapes.isEmpty) return true;

    // Snapshot existing ids for this controller so we can partition
    // incoming shapes into updates vs appends.
    final existing = _MapRegistry.getRawMarkers(id);
    final existingIds = <String>{};
    for (final e in existing) {
      try {
        if (e is ShapeMeta && e.id != null) existingIds.add(e.id!);
        if (e is Map && e['id'] is String) existingIds.add(e['id'] as String);
      } catch (_) {}
    }

    final toAppend = <dynamic>[];
    final updates = <Map<String, dynamic>>[];

    for (final s in shapes) {
      try {
        final sid = s.id;
        if (sid != null && existingIds.contains(sid)) {
          // Prepare update payload: include full pointMetas when present
          final map = <String, dynamic>{'id': sid};
          if (s.pointMetas != null) {
            map['pointMetas'] = s.pointMetas!
                .map((pm) => pm.toMap())
                .toList(growable: false);
          }
          updates.add(map);
        } else {
          // New entry: append ShapeMeta directly so notifier will register
          toAppend.add(s);
        }
      } catch (_) {}
    }

    // Apply updates in a single batch if any
    try {
      if (updates.isNotEmpty) {
        // Use static batchUpdateCoordinates which will forward to
        // the notifier and respect useInPlaceMutation flag.
        batchUpdateCoordinates(
          id,
          updates,
          createMarkerWidgets: createMarkerWidgets,
          useInPlaceMutation: useInPlaceMutation,
        );
      }
    } catch (_) {}

    // Append new entries if any
    if (toAppend.isNotEmpty) {
      var appended = false;
      try {
        // Returns false when the map never became ready. That is not an
        // exception, so the result has to be checked here.
        appended = await _MapRawMarkerOps.appendRawMarkers(
          id,
          List<dynamic>.from(toAppend),
          createMarkerWidgets: createMarkerWidgets,
        );
      } catch (_) {
        appended = false;
      }
      if (!appended) {
        try {
          // Fallback: store the entries in rawMarkers directly. Do not call
          // _MapRawMarkerOps.setRawMarkers here. It clears every polygon, polyline, circle and
          // marker first, and that would wipe the other shapes.
          final n = _MapRegistry._getNotifier(id);
          if (n != null) {
            n.rawMarkers = List<dynamic>.from(n.rawMarkers)..addAll(toAppend);
          }
        } catch (_) {}
      }
    }

    return true;
  }

  /// Efficiently apply many raw-marker updates for [id] in a single batch.
  /// Returns true when the notifier exists and the operation was applied.
  static Future<bool> batchUpdateRawMarkers(
    String id,
    List<dynamic> updates, {
    bool createMarkerWidgets = true,
  }) async {
    var n = _MapRegistry._getNotifier(id);
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        _MapRegistry.registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return false;

    // Decide whether to show blocking overlay for large batches.
    final shouldBlock = updates.length >= _MapRegistry._autoBlockingThreshold;
    try {
      if (shouldBlock) {
        try {
          _MapRegistry._blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          _MapRegistry.setBlockingLoading(id, true);
        } catch (_) {}
        try {
          await Future.delayed(Duration.zero);
        } catch (_) {}
      }

      // Delegate to notifier batch implementation which rebuilds caches
      // once and schedules a debounced notify.
      try {
        n.batchUpdateRawMarkers(
          updates,
          createMarkerWidgets: createMarkerWidgets,
        );
      } catch (_) {
        try {
          // Fallback: apply per-item _MapRawMarkerOps.updateRawMarker
          for (final u in updates) {
            String? idv;
            if (u is ShapeMeta) idv = u.id;
            if (u is Map) idv = (u['id'] as String?);
            if (idv != null) {
              _MapRawMarkerOps.updateRawMarker(id, idv, u);
            } else {
              await _MapRawMarkerOps.appendRawMarkers(id, [
                u,
              ], createMarkerWidgets: createMarkerWidgets);
            }
          }
        } catch (_) {}
      }

      try {
        if (_MapRegistry.enableBatchLogging) {
          debugLog(
            '[FormFieldsMapController] batchUpdateRawMarkers id=$id updates=${updates.length} total=${n.rawMarkers.length}',
          );
        }
      } catch (_) {}
      return true;
    } finally {
      if (shouldBlock) {
        try {
          _MapRegistry._blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          _MapRegistry._blockingClearTimers[id] = Timer(
            const Duration(milliseconds: 200),
            () {
              try {
                _MapRegistry.setBlockingLoading(id, false);
              } catch (_) {}
              _MapRegistry._blockingClearTimers.remove(id);
            },
          );
        } catch (_) {}
      }
    }
  }

  /// Upsert a single raw marker: update if an entry with [markerId] exists,
  /// otherwise insert it. Returns true when the notifier exists and the
  /// operation was applied.
  static Future<bool> upsertRawMarker(
    String id,
    String markerId,
    dynamic entry, {
    bool createMarkerWidgets = true,
  }) async {
    // Ensure the entry carries the id so batch logic treats it as a
    // replacement when possible.
    try {
      if (entry is ShapeMeta) {
        entry.id = markerId;
      } else if (entry is Map) {
        entry['id'] = markerId;
      }
    } catch (_) {}
    return await batchUpdateRawMarkers(id, [
      entry,
    ], createMarkerWidgets: createMarkerWidgets);
  }

  /// Update only coordinates of an existing raw marker or append if missing.
  /// This fast-path delegates to the notifier to avoid full derived-map
  /// rebuilds and returns true when applied.
  static bool updateRawMarkerCoordinates(
    String id,
    String markerId,
    List<PointMeta> newPointMetas, {
    bool createMarkerWidgets = true,
  }) {
    final n = _MapRegistry._getNotifier(id);
    if (n == null) return false;
    try {
      n.upsertCoordinates(
        markerId,
        newPointMetas,
        createMarkerWidgets: createMarkerWidgets,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
