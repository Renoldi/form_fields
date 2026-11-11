import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/fields/core/form_fields_live_camera_capture.dart';

/// Stands in for the native camera. Every camera fails to initialize, the way
/// a device with a busy camera does, and each dispose is recorded.
class _FailingCameraPlatform extends CameraPlatform {
  _FailingCameraPlatform({this.hang = false});

  /// When true, `initializeCamera` never completes, like a stuck device.
  final bool hang;
  final List<int> disposed = [];
  final StreamController<CameraInitializedEvent> _initialized =
      StreamController<CameraInitializedEvent>.broadcast();

  @override
  Future<List<CameraDescription>> availableCameras() async => const [
    CameraDescription(
      name: 'front',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 90,
    ),
  ];

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings mediaSettings,
  ) async => 1;

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      _initialized.stream;

  // The plugin calls `.first` on these, so they must stay open with no events.
  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      StreamController<CameraErrorEvent>().stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream<DeviceOrientationChangedEvent>.empty();

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    if (hang) return Completer<void>().future;
    throw PlatformException(code: 'camera_busy', message: 'in use');
  }

  @override
  Future<void> dispose(int cameraId) async {
    disposed.add(cameraId);
  }
}

void main() {
  late _FailingCameraPlatform platform;

  setUp(() {
    platform = _FailingCameraPlatform();
    CameraPlatform.instance = platform;
  });

  test('a failed initialize releases the camera it opened', () async {
    final manager = SharedCameraManager.instance;

    await manager.acquire();
    manager.release();
    // dispose() is not awaited, so let it run.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(platform.disposed, [1]);
    expect(manager.isReady, isFalse);
  });

  test(
    'acquire returns after a failed initialize instead of hanging',
    () async {
      final manager = SharedCameraManager.instance;

      await manager.acquire().timeout(const Duration(seconds: 5));
      manager.release();
      expect(manager.isReady, isFalse);
    },
  );

  test(
    'a camera that never finishes initializing does not hang acquire',
    () async {
      CameraPlatform.instance = _FailingCameraPlatform(hang: true);
      final manager = SharedCameraManager.instance;

      // The plugin's initialize times out after 2 seconds. acquire must return
      // then, even though the platform call is still pending.
      await manager.acquire().timeout(const Duration(seconds: 6));
      manager.release();
      expect(manager.isReady, isFalse);
    },
  );
}
