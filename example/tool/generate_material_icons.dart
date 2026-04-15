// Save this as tools/generate_material_icons.dart and run with `dart run tools/generate_material_icons.dart`
// Make sure to update the path to your Flutter SDK if needed.

import 'dart:io';

void main() async {
  // Update this path to your Flutter SDK location if needed
  final flutterSdkPath = Platform.environment['FLUTTER_ROOT'] ?? '/path/to/flutter';
  final iconsFile = File('$flutterSdkPath/packages/flutter/lib/src/material/icons.dart');

  if (!await iconsFile.exists()) {
    print('Could not find icons.dart at $iconsFile');
    exit(1);
  }

  final lines = await iconsFile.readAsLines();
  final iconMap = <String, String>{};

  final iconRegExp = RegExp(r'static const IconData (\w+) = IconData\(');

  for (final line in lines) {
    final match = iconRegExp.firstMatch(line);
    if (match != null) {
      final name = match.group(1)!;
      iconMap[name] = "Icons.$name";
    }
  }

  print('const Map<String, IconData> kAllMaterialIcons = {');
  for (final entry in iconMap.entries) {
    print("  '${entry.key}': ${entry.value},");
  }
  print('};');
}