import 'package:flutter/foundation.dart';
import 'package:form_fields_example/data/models/post.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:form_fields/form_fields.dart';
import 'pending_submission_helper.dart';

final Logger _sendLocationLogger = Logger();

@pragma('vm:entry-point')
Future<bool> sendCurrentLocationBackgroundHandler(
    String task, Map<String, dynamic>? inputData) async {
  bool acquiredHere = false;
  Map<String, double>? location;
  try {
    if (kDebugMode) {
      // ignore: avoid_print
      print('sendCurrentLocationBackgroundHandler invoked: $task');
    }
    final skip = WorkmanagerService.isInCountdownInvocation;
    _sendLocationLogger.i(
        'sendCurrentLocationBackgroundHandler: skip=$skip isFlushing=${WorkmanagerService.isFlushing} guardSetAt=${WorkmanagerService.flushGuardSetAt} inCountdown=${WorkmanagerService.isInCountdownInvocation}');
    acquiredHere = WorkmanagerService.acquireFlushGuard(skip: skip);
    if (!skip && !acquiredHere) {
      _sendLocationLogger.i(
          'sendCurrentLocationBackgroundHandler: another flush in progress — skipping');
      return false;
    }

    _sendLocationLogger.i('Background handler invoked for $task');
    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.best));
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
    Post post = Post(
      userId: 1,
      title: 'Current Location',
      body:
          'Location data: ${location != null ? 'lat=${location['lat']}, lng=${location['lng']}' : 'unknown'}',
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
      'sendCurrentLocationForeground: skip=$skip isFlushing=${WorkmanagerService.isFlushing} guardSetAt=${WorkmanagerService.flushGuardSetAt} inCountdown=${WorkmanagerService.isInCountdownInvocation}');
  final acquiredHere = WorkmanagerService.acquireFlushGuard(skip: skip);
  if (!skip && !acquiredHere) {
    _sendLocationLogger.i(
        'sendCurrentLocationForeground: another flush in progress — skipping');
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
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.best));
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
    Post post = Post(
      userId: 1,
      title: 'Current Location',
      body:
          'Location data: ${location != null ? 'lat=${location['lat']}, lng=${location['lng']}' : 'unknown'}',
      tags: ['location', 'background'],
    );

    final id = await DBService.instance.insertOrUpdate('pending_submissions', {
      'payload': post.toJson(),
      'status': 'pending',
    });
    if (id > 0) {
      _sendLocationLogger.i('Foreground inserted pending location id=$id');
    }
  } catch (e, st) {
    _sendLocationLogger.w('Foreground handler threw: $e\n$st');
  } finally {
    if (acquiredHere) WorkmanagerService.releaseFlushGuard();
  }
}
