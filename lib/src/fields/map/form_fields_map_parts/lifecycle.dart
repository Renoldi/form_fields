part of '../form_fields_map.dart';

extension _FormFieldsMapLifecycleX on FormFieldsMapState {
  /// Lifecycle logic moved out of the override (see `initState`).
  void _initializeMapState() {
    // Determine controller ownership and registry id. If a MapController
    // was provided by the consumer, register it under a stable id derived
    // from its hashCode so it is discoverable via the registry. Otherwise
    // create or reuse a controller in the registry using a generated id.
    if (widget.controller != null) {
      _mapController = widget.controller!;
      _controllerId = 'ff_controller_${widget.controller.hashCode}';
      FormFieldsMapController.registerController(_controllerId, _mapController);
      _ownsController = false;
    } else {
      _controllerId =
          'ff_internal_${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(this)}';
      _mapController = FormFieldsMapController.getOrCreate(_controllerId);
      _ownsController = true;
    }

    _fallbackNotifier = FormFieldsMapNotifier();

    // Shared geocoding service instance for reverse/search operations.
    _geocodingService = GeocodingService();

    // Register the internal fallback notifier only when no notifier has been
    // previously registered for this controller id. This prevents the widget
    // from overwriting a notifier that a consumer (or example) already
    // registered before the widget was built.
    try {
      final existing = FormFieldsMapController.getNotifier(_controllerId);
      try {
        debugLog(
          '[FormFieldsMap] initState controllerId=$_controllerId existingNotifier=${existing?.hashCode} fallback=${_fallbackNotifier.hashCode}',
        );
      } catch (_) {}
      if (existing == null) {
        FormFieldsMapController.registerNotifier(
          _controllerId,
          _fallbackNotifier,
        );
      }
    } catch (_) {}

    // Notifier lifecycle is managed externally via FormFieldsMapController.
    // The widget no longer accepts a `notifier` parameter.
    // Not called here: it reads the theme and asset bundle through the
    // context, and Flutter does not allow that from initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resolveCanvasMarkerIcon();
    });
    _playbackInterval = _playbackIntervalEffective;
    _playbackInterpolationSteps = _playbackInterpolationStepsEffective;
    _playbackSubstepInterval = _computeSubstepInterval(
      _playbackInterval,
      _playbackInterpolationSteps,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(widget.initialCenter, widget.initialZoom);
      } catch (_) {}
      widget.onMapReady?.call();
      // Ensure the widget rebuilds after the controller move so tile layers
      // begin fetching immediately instead of waiting for an interaction.
      try {
        _safeSetState(() {});
      } catch (_) {}
    });

    FormFieldsMapController.registerOnMarkerTap(
      _controllerId,
      widget.onTapShape,
    );

    // Register playback handler so external callers can control playback via
    // `FormFieldsMapController`.
    if (_playbackEnabled) {
      FormFieldsMapController.registerPlaybackHandler(
        _controllerId,
        FormFieldsMapPlaybackHandler(
          start: (polylineId) => _startPolylinePlayback(polylineId),
          pause: () => _pausePolylinePlayback(),
          restart: () => _restartPolylinePlayback(),
          setInterval: (d) => _setPolylinePlaybackInterval(d),
          setInterpolationSteps: (s) => _setPlaybackInterpolationSteps(s),
          toggle: (polylineId) => _togglePolylinePlayback(polylineId),
          stepForward: (polylineId) => _stepPlaybackForward(polylineId),
          stepBackward: (polylineId) => _stepPlaybackBackward(polylineId),
        ),
      );
      // Configure whether this widget wants auto-start on first append.
      try {
        FormFieldsMapController.setPlaybackAutoStart(
          _controllerId,
          widget.playbackConfig?.playbackAutoStart ?? false,
        );
      } catch (_) {}
    }
  }

  /// Lifecycle logic moved out of the override (see `didUpdateWidget`).
  void _applyWidgetUpdate(FormFieldsMap oldWidget) {
    if (oldWidget.mapConfig?.canvasMarkerIcon !=
        widget.mapConfig?.canvasMarkerIcon) {
      _resolveCanvasMarkerIcon();
    }
    // If playback-specific icon changes, ensure we re-rasterize images.
    if (oldWidget.playbackConfig?.playbackMarkerIcon !=
        widget.playbackConfig?.playbackMarkerIcon) {
      _resolveCanvasMarkerIcon();
    }

    // Notifier removed from widget API; notifier lifecycle is no-op here.

    final oldId = _controllerId;
    // If the consumer provided a different controller instance, switch to
    // a new registry id and update registrations accordingly.
    if (oldWidget.controller != widget.controller) {
      // Unregister handlers from the old id
      FormFieldsMapController.removeOnMarkerTap(oldId);
      FormFieldsMapController.unregisterPlaybackHandler(oldId);
      // An internal controller created for the old id is no longer used. Drop
      // its registry entries, or each controller swap leaves one behind.
      if (_ownsController) {
        FormFieldsMapController.remove(oldId);
      }

      if (widget.controller != null) {
        _mapController = widget.controller!;
        _controllerId = 'ff_controller_${widget.controller.hashCode}';
        FormFieldsMapController.registerController(
          _controllerId,
          _mapController,
        );
        _ownsController = false;
      } else {
        _controllerId =
            'ff_internal_${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(this)}';
        _mapController = FormFieldsMapController.getOrCreate(_controllerId);
        _ownsController = true;
      }
      // Register new handlers below
      // Ensure the fallback notifier is moved from the old id to the new id
      // so controller-based mutations continue to update this widget.
      try {
        final existingOld = FormFieldsMapController.getNotifier(oldId);
        if (identical(existingOld, _fallbackNotifier)) {
          FormFieldsMapController.removeNotifier(oldId);
        }
      } catch (_) {}
      try {
        final existing = FormFieldsMapController.getNotifier(_controllerId);
        try {
          debugLog(
            '[FormFieldsMap] didUpdateWidget moved controller oldId=$oldId newId=$_controllerId existingNotifier=${existing?.hashCode} fallback=${_fallbackNotifier.hashCode}',
          );
        } catch (_) {}
        if (existing == null) {
          FormFieldsMapController.registerNotifier(
            _controllerId,
            _fallbackNotifier,
          );
        }
      } catch (_) {}
    }

    if (oldWidget.onTapShape != widget.onTapShape || oldId != _controllerId) {
      FormFieldsMapController.removeOnMarkerTap(oldId);
      FormFieldsMapController.registerOnMarkerTap(
        _controllerId,
        widget.onTapShape,
      );
      // Move playback handler registration when controller id changes.
      FormFieldsMapController.unregisterPlaybackHandler(oldId);
      if (_playbackEnabled) {
        FormFieldsMapController.registerPlaybackHandler(
          _controllerId,
          FormFieldsMapPlaybackHandler(
            start: (polylineId) => _startPolylinePlayback(polylineId),
            pause: () => _pausePolylinePlayback(),
            restart: () => _restartPolylinePlayback(),
            setInterval: (d) => _setPolylinePlaybackInterval(d),
            setInterpolationSteps: (s) => _setPlaybackInterpolationSteps(s),
            toggle: (polylineId) => _togglePolylinePlayback(polylineId),
            stepForward: (polylineId) => _stepPlaybackForward(polylineId),
            stepBackward: (polylineId) => _stepPlaybackBackward(polylineId),
          ),
        );
        try {
          FormFieldsMapController.setPlaybackAutoStart(
            _controllerId,
            widget.playbackConfig?.playbackAutoStart ?? false,
          );
        } catch (_) {}
      }
    }

    // Handle changes to playback configuration (widget-level or via playbackConfig)
    final oldInterval =
        oldWidget.playbackConfig?.playbackInterval ??
        const Duration(seconds: 1);
    final newInterval =
        widget.playbackConfig?.playbackInterval ?? const Duration(seconds: 1);
    final oldSteps = oldWidget.playbackConfig?.playbackInterpolationSteps ?? 0;
    final newSteps = widget.playbackConfig?.playbackInterpolationSteps ?? 0;
    if (oldInterval != newInterval || oldSteps != newSteps) {
      _playbackInterval = newInterval;
      _playbackInterpolationSteps = newSteps;
      _playbackSubstepInterval = _computeSubstepInterval(
        _playbackInterval,
        _playbackInterpolationSteps,
      );
      if (_isPlaying) {
        _playbackTimer?.cancel();
        _playbackTimer = Timer.periodic(
          _playbackSubstepInterval,
          (_) => _advancePlaybackStep(),
        );
      }
      // rebuild points if playing
      if (_playbackPolylineId != null) {
        final notifier =
            FormFieldsMapController.getNotifier(_controllerId) ??
            _fallbackNotifier;
        final pl = notifier.polylineMap[_playbackPolylineId];
        if (pl != null) {
          _playbackPoints = _buildInterpolatedPoints(
            pl.points,
            _playbackInterpolationSteps,
          );
          // Fewer interpolation steps means a shorter list. Keep the index in
          // range, or the next step reads past the end.
          _playbackIndex = _playbackIndex.clamp(
            0,
            max(0, _playbackPoints.length - 1),
          );
        }
      }
    }
  }
}
