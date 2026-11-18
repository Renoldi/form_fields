import 'package:flutter/foundation.dart';
import 'package:form_fields_example/data/models/post.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:form_fields/form_fields.dart';
import 'pending_submission_helper.dart';

final Logger _sendLocationLogger = Logger();

/// Whether the app may read the device location right now. Never shows a
/// dialog, so it is safe in background workers and startup handlers.
Future<bool> hasLocationPermission() async {
  final permission = await Geolocator.checkPermission();
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}

/// Background location is a separate grant ("Allow all the time"). Android 10+
/// requires it on top of the foreground permission, and a background worker
/// can only use it when it has been granted.
Future<bool> hasBackgroundLocationPermission() async {
  final permission = await Geolocator.checkPermission();
  return permission == LocationPermission.always;
}

/// Asks for background location, after the foreground permission. Android 11+
/// does not show "Allow all the time" inline, so when the system refuses the
/// request the user is sent to the app settings to choose it there.
Future<bool> requestBackgroundLocationPermission() async {
  if (!await requestLocationPermission()) return false;
  if (await hasBackgroundLocationPermission()) return true;
  final status = await Permission.locationAlways.request();
  if (status.isGranted) return true;
  if (status.isPermanentlyDenied || status.isDenied) {
    await openAppSettings();
  }
  return hasBackgroundLocationPermission();
}

/// Asks the user for location permission. Call this from a user action (for
/// example a button tap), never from startup or a background worker.
Future<bool> requestLocationPermission() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}

@pragma('vm:entry-point')
Future<bool> sendCurrentLocationBackgroundHandler(
  String task,
  Map<String, dynamic>? inputData,
) async {
  bool acquiredHere = false;
  Map<String, double>? location;
  try {
    if (kDebugMode) {
      // ignore: avoid_print
      print('sendCurrentLocationBackgroundHandler invoked: $task');
    }
    final skip = WorkmanagerService.isInCountdownInvocation;
    _sendLocationLogger.i(
      'sendCurrentLocationBackgroundHandler: skip=$skip isFlushing=${WorkmanagerService.isFlushing} guardSetAt=${WorkmanagerService.flushGuardSetAt} inCountdown=${WorkmanagerService.isInCountdownInvocation}',
    );
    acquiredHere = WorkmanagerService.acquireFlushGuard(skip: skip);
    if (!skip && !acquiredHere) {
      _sendLocationLogger.i(
        'sendCurrentLocationBackgroundHandler: another flush in progress — skipping',
      );
      return false;
    }

    _sendLocationLogger.i('Background handler invoked for $task');
    try {
      if (!await hasBackgroundLocationPermission()) {
        _sendLocationLogger.i(
          'Background location not granted; skipping $task',
        );
        return true;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      location = {'lat': pos.latitude, 'lng': pos.longitude};
      _sendLocationLogger.i('Current location fetched: $location');
    } catch (e, st) {
      _sendLocationLogger.w('Failed to fetch location: $e\n$st');
      location = null;
    }

    // final payload = {
    //   'type': 'location',
    //   'source': task,
    //   'ts': DateTime.now().toIso8601String(),
    //   'location': location == null
    //       ? null
    //       : {'lat': location['lat'], 'lng': location['lng']},
    // };
    if (location == null) {
      _sendLocationLogger.w('No location fix; nothing to send for $task');
      return true;
    }
    Post post = Post(
      userId: 1,
      title: 'Current Location',
      body: 'Location data: lat=${location['lat']}, lng=${location['lng']}',
      tags: ['location', 'background'],
    );

    final id = await addPendingSubmission(post.toJson());
    if (id > 0) {
      _sendLocationLogger.i('Inserted pending location payload id=$id');
    } else {
      _sendLocationLogger.w('Failed to persist pending location');
    }

    return true;
  } catch (e, st) {
    _sendLocationLogger.w('Background handler failed: $e\n$st');
    return false;
  } finally {
    if (acquiredHere) WorkmanagerService.releaseFlushGuard();
  }
}

@pragma('vm:entry-point')
Future<void> sendCurrentLocationForeground() async {
  final skip = WorkmanagerService.isInCountdownInvocation;
  _sendLocationLogger.i(
    'sendCurrentLocationForeground: skip=$skip isFlushing=${WorkmanagerService.isFlushing} guardSetAt=${WorkmanagerService.flushGuardSetAt} inCountdown=${WorkmanagerService.isInCountdownInvocation}',
  );
  final acquiredHere = WorkmanagerService.acquireFlushGuard(skip: skip);
  if (!skip && !acquiredHere) {
    _sendLocationLogger.i(
      'sendCurrentLocationForeground: another flush in progress — skipping',
    );
    return;
  }

  try {
    Map<String, double>? location;
    if (kDebugMode) {
      // ignore: avoid_print
      print('sendCurrentLocationForeground invoked');
    }
    _sendLocationLogger.i('Foreground handler invoked');
    try {
      if (!await hasLocationPermission()) {
        _sendLocationLogger.i('Location permission not granted; skipping');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      location = {'lat': pos.latitude, 'lng': pos.longitude};
      _sendLocationLogger.i('Foreground current location fetched: $location');
    } catch (e, st) {
      _sendLocationLogger.w('Foreground failed to fetch location: $e\n$st');
      location = null;
    }
    // final payload = {
    //   'type': 'location',
    //   'source': 'foreground',
    //   'ts': DateTime.now().toIso8601String(),
    //   'location': location == null
    //       ? null
    //       : {'lat': location['lat'], 'lng': location['lng']},
    // };
    // final id = await addPendingSubmission(payload);
    if (location == null) {
      _sendLocationLogger.w('No location fix; nothing to send');
      return;
    }
    Post post = Post(
      userId: 1,
      title: 'Current Location',
      body: 'Location data: lat=${location['lat']}, lng=${location['lng']}',
      tags: ['location', 'background'],
    );

    final id = await DBService.instance.insertOrUpdate('pending_submissions', {
      'payload': post.toJson(),
      'status': 'pending',
    });
    if (id > 0) {
      _sendLocationLogger.i('Foreground inserted pending location id=$id');
      try {
        WorkmanagerService.instance.notifyPendingAdded();
      } catch (_) {}
    }
  } catch (e, st) {
    _sendLocationLogger.w('Foreground handler threw: $e\n$st');
  } finally {
    if (acquiredHere) WorkmanagerService.releaseFlushGuard();
  }
}
