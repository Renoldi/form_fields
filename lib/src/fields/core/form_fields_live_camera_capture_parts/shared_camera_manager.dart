part of '../form_fields_live_camera_capture.dart';

class SharedCameraManager {
  SharedCameraManager._();
  static final SharedCameraManager instance = SharedCameraManager._();

  CameraController? _controller;
  int _refCount = 0;
  bool _initializing = false;
  String? _errorMessage;

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback cb) {
    _listeners.add(cb);
    debugLog(
      '[SharedCameraManager] addListener; listeners=${_listeners.length}',
    );
  }

  void removeListener(VoidCallback cb) {
    _listeners.remove(cb);
    debugLog(
      '[SharedCameraManager] removeListener; listeners=${_listeners.length}',
    );
  }

  void _notify() {
    debugLog(
      '[SharedCameraManager] _notify; listeners=${_listeners.length}; isReady=$isReady; initializing=$_initializing; ref=$_refCount',
    );
    for (final l in List<VoidCallback>.of(_listeners)) {
      try {
        l();
      } catch (e, st) {
        debugLog('[SharedCameraManager] listener threw: $e\n$st');
      }
    }
  }

  Future<void> acquire([
    ResolutionPreset preset = ResolutionPreset.medium,
  ]) async {
    _refCount++;
    if (_controller != null && _controller!.value.isInitialized) return;
    if (_initializing) {
      await Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return _initializing;
      });
      return;
    }
    _initializing = true;
    _errorMessage = null;
    try {
      debugLog('[SharedCameraManager] acquiring cameras...');
      // Give the camera init a reasonable timeout to avoid indefinite spinner.
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw Exception('availableCameras() timeout');
        },
      );
      if (cameras.isEmpty) {
        _errorMessage = 'cameraNoCamerasFound';
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      debugLog(
        '[SharedCameraManager] initializing controller for ${front.name}',
      );
      final ctrl = CameraController(front, preset, enableAudio: false);
      try {
        await ctrl.initialize().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            throw Exception('CameraController.initialize() timeout');
          },
        );
      } catch (_) {
        // A failed or timed-out initialize can leave the device camera open.
        // Release it, or the next attempt finds the camera busy. Not awaited:
        // CameraController.dispose() waits for the pending initialize to end,
        // and after a timeout that may never happen. Waiting here would hang
        // every later acquire().
        ctrl.dispose().catchError((_) {});
        rethrow;
      }
      if (_refCount == 0) {
        // Every user released while this was initializing. Nothing will ever
        // release the camera again, so release it now.
        ctrl.dispose().catchError((_) {});
        debugLog('[SharedCameraManager] released during init; disposed');
        return;
      }
      _controller = ctrl;
      debugLog('[SharedCameraManager] camera initialized');
    } catch (e, st) {
      final msg = e.toString();
      if (msg.contains('availableCameras() timeout')) {
        _errorMessage = 'cameraAvailableTimeout';
      } else if (msg.contains('CameraController.initialize() timeout')) {
        _errorMessage = 'cameraInitializeTimeout';
      } else {
        _errorMessage = msg;
      }
      debugLog('[SharedCameraManager] acquire failed: $e\n$st');
    } finally {
      _initializing = false;
      debugLog(
        '[SharedCameraManager] acquire finished; initializing=$_initializing; error=$_errorMessage; ref=$_refCount; isReady=$isReady',
      );
      _notify();
    }
  }

  void release() {
    _refCount = (_refCount - 1).clamp(0, double.maxFinite.toInt());
    debugLog('[SharedCameraManager] release called; refCount=$_refCount');
    if (_refCount == 0) {
      _controller?.dispose();
      _controller = null;
      _errorMessage = null;
      debugLog('[SharedCameraManager] controller disposed');
    }
  }

  CameraController? get controller => _controller;
  String? get errorMessage => _errorMessage;
  bool get isReady => _controller != null && _controller!.value.isInitialized;
}
