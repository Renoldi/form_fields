import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// iOS crashes when a BGTask identifier is used but not listed in
/// `BGTaskSchedulerPermittedIdentifiers`. This guards the example app: every
/// worker name it registers must be permitted in its Info.plist.
void main() {
  test('every example worker is a permitted iOS BGTask identifier', () {
    // Ignore commented-out code, which can mention names that are not live.
    final main = File('example/lib/main.dart')
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');
    final plist = File('example/ios/Runner/Info.plist').readAsStringSync();

    final workerNames = RegExp(
      r"taskName:\s*'([^']+)'",
    ).allMatches(main).map((m) => m.group(1)!).toSet();
    expect(
      workerNames,
      isNotEmpty,
      reason: 'no worker names found in main.dart',
    );

    final permitted = RegExp(
      r'<key>BGTaskSchedulerPermittedIdentifiers</key>\s*<array>(.*?)</array>',
      dotAll: true,
    ).firstMatch(plist);
    expect(
      permitted,
      isNotNull,
      reason: 'BGTaskSchedulerPermittedIdentifiers missing',
    );

    final identifiers = RegExp(
      r'<string>([^<]+)</string>',
    ).allMatches(permitted!.group(1)!).map((m) => m.group(1)!).toSet();
    expect(identifiers, containsAll(workerNames));
  });

  test('AppDelegate registers every example worker before launch finishes', () {
    final main = File('example/lib/main.dart')
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');
    final appDelegate = File(
      'example/ios/Runner/AppDelegate.swift',
    ).readAsStringSync();

    final workerNames = RegExp(
      r"taskName:\s*'([^']+)'",
    ).allMatches(main).map((m) => m.group(1)!);
    for (final name in workerNames) {
      expect(
        appDelegate,
        contains("\"$name\""),
        reason: 'AppDelegate must register launch handler for $name',
      );
    }
    expect(appDelegate, contains('registerPeriodicTask(withIdentifier:'));
    expect(appDelegate, contains('registerBGProcessingTask(withIdentifier:'));
  });

  test('iOS background modes needed by Workmanager are declared', () {
    final plist = File('example/ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>UIBackgroundModes</key>'));
    expect(plist, contains('<string>fetch</string>'));
    expect(plist, contains('<string>processing</string>'));
  });
}
