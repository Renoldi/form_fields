part of '../form_fields_map.dart';

/// Overlay layers stacked above the map: center marker, playback controls,
/// loading indicators.
extension _FormFieldsMapOverlaysX on FormFieldsMapState {
  Widget _buildCenterMarker({required BuildContext context}) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Builder(
            builder: (ctx) {
              // Priority: `findConfig.centerMarker` -> explicit
              // `widget.centerMarker` -> rasterized `_canvasMarkerImage`
              // -> provided `canvasMarkerIcon` -> default icon.
              final centerWidget =
                  _findConfigEffective.centerMarker ?? widget.centerMarker;
              if (centerWidget != null) return centerWidget;
              if (_canvasMarkerImage != null) {
                return RawImage(
                  image: _canvasMarkerImage,
                  width: _canvasMarkerRadiusEffective * 2,
                  height: _canvasMarkerRadiusEffective * 2,
                  fit: BoxFit.contain,
                );
              }
              final provider = _canvasMarkerIconEffective;
              if (provider is Widget) return provider;
              if (provider is Icon) return provider;
              if (provider is ImageProvider) {
                return Image(
                  image: provider,
                  width: _canvasMarkerRadiusEffective * 2,
                  height: _canvasMarkerRadiusEffective * 2,
                  fit: BoxFit.contain,
                );
              }
              return Icon(
                Icons.location_pin,
                color: Theme.of(context).colorScheme.onSecondary,
                size: 36,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls({required BuildContext context}) {
    return Positioned(
      right: 10,
      top: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_playbackEnabled) ...[
            // Card(
            //   elevation: 2,
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(
            //         horizontal: 8.0, vertical: 6.0),
            //     child: Text(
            //       'Zoom: ${(_lastZoom ?? widget.initialZoom).toStringAsFixed(1)}',
            //       style: const TextStyle(fontSize: 12),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 8),
            AppButton(
              type: AppButtonType.fab,
              size: AppSize.small,
              icon: const Icon(Icons.add),
              useSafeArea: false,
              heroTag: null,
              onPressed: () {
                final center = _lastCenter ?? widget.initialCenter;
                final currentZoom = _lastZoom ?? widget.initialZoom;
                final newZoom = (currentZoom + 1).clamp(
                  widget.minZoom,
                  widget.maxZoom,
                );
                animateTo(center, newZoom);
              },
            ),
            const SizedBox(height: 8),
            AppButton(
              type: AppButtonType.fab,
              size: AppSize.small,
              isLoading: _centerActionInProgress,
              icon: const Icon(Icons.my_location),
              useSafeArea: false,
              heroTag: null,
              onPressed: () => _centerMapOnCurrentLocation(),
            ),
            const SizedBox(height: 8),
            if (_showMarkerInCenterEffective)
              AppButton(
                type: AppButtonType.fab,
                size: AppSize.small,
                isLoading: _centerActionInProgress,
                icon: const Icon(Icons.check),
                useSafeArea: false,
                heroTag: null,
                onPressed: () async {
                  if (_centerActionInProgress) return;
                  _applyStateChange(() {
                    _centerActionInProgress = true;
                  });
                  final center = _lastCenter ?? widget.initialCenter;
                  String address = '';
                  PointMeta? pm;
                  try {
                    String? cbAddress;
                    if (_reverseGeocodeEffective != null) {
                      try {
                        cbAddress = await _reverseGeocodeEffective!(center);
                      } catch (_) {
                        cbAddress = null;
                      }
                    }

                    if (cbAddress != null && cbAddress.isNotEmpty) {
                      address = cbAddress;
                      pm = PointMeta(
                        lat: center.latitude,
                        lon: center.longitude,
                        address: address,
                      );
                    } else if (_findConfigEffective.allowGeolocation) {
                      pm = await _geocodingService.reverseToPointMeta(center);
                      address = pm?.address ?? '';
                    } else {
                      address = '';
                      pm = null;
                    }
                  } catch (_) {
                    address = '';
                  }
                  try {
                    if (_onCenterMarkerEffective != null) {
                      await _onCenterMarkerEffective!(
                        FormFieldsLocationPrediction(
                          latLng: pm?.point ?? center,
                          address: address,
                        ),
                      );
                    }
                  } catch (_) {
                  } finally {
                    if (mounted) {
                      _applyStateChange(() {
                        _centerActionInProgress = false;
                      });
                    }
                  }
                },
              ),
            const SizedBox(height: 8),
            AppButton(
              type: AppButtonType.fab,
              size: AppSize.small,
              icon: const Icon(Icons.remove),
              useSafeArea: false,
              heroTag: null,
              onPressed: () {
                final center = _lastCenter ?? widget.initialCenter;
                final currentZoom = _lastZoom ?? widget.initialZoom;
                final newZoom = (currentZoom - 1).clamp(
                  widget.minZoom,
                  widget.maxZoom,
                );
                animateTo(center, newZoom);
              },
            ),
            const SizedBox(height: 8),
          ],
          if (_playbackEnabled && _showBuiltinPlaybackControlsEffective) ...[
            AppButton(
              type: AppButtonType.fab,
              size: AppSize.small,
              icon: const Icon(Icons.skip_previous),
              useSafeArea: false,
              heroTag: null,
              onPressed: () => _stepPlaybackBackward(null),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable:
                  FormFieldsMapController.getPlaybackPlayingListenable(
                    _controllerId,
                  ),
              builder: (context, playing, _) {
                return AppButton(
                  type: AppButtonType.fab,
                  size: AppSize.small,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  useSafeArea: false,
                  heroTag: null,
                  onPressed: () => _togglePolylinePlayback(null),
                );
              },
            ),
            const SizedBox(height: 8),
            AppButton(
              type: AppButtonType.fab,
              size: AppSize.small,
              icon: const Icon(Icons.skip_next),
              useSafeArea: false,
              heroTag: null,
              onPressed: () => _stepPlaybackForward(null),
            ),
            const SizedBox(height: 8),
            AppButton(
              type: AppButtonType.fab,
              size: AppSize.small,
              icon: const Icon(Icons.replay),
              useSafeArea: false,
              heroTag: null,
              onPressed: () => _restartPolylinePlayback(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlockingLoadingOverlay({required BuildContext context}) {
    return // Full-screen blocking overlay for data loads.
    ValueListenableBuilder<bool>(
      valueListenable: FormFieldsMapController.getBlockingLoadingListenable(
        _controllerId,
      ),
      builder: (context, isBlocking, _) {
        if (isBlocking) {
          return Positioned.fill(
            child: Stack(
              children: [
                const ModalBarrier(dismissible: false, color: Colors.black38),
                Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.formTr('loading'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCameraActivityIndicator({required BuildContext context}) {
    return // Small non-blocking indicator for brief camera/position updates.
    ValueListenableBuilder<bool>(
      valueListenable: FormFieldsMapController.getLoadingListenable(
        _controllerId,
      ),
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const Positioned(
            right: 12,
            top: 12,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
