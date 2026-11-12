/// String extensions for validation and manipulation
library;

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

/// Local part, then one or more dot-separated labels, then "@" and a domain
/// whose last label is at least two letters long.
final RegExp _emailPattern = RegExp(
  r"^[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)*"
  r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?'
  r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)*'
  r'\.[a-zA-Z]{2,}$',
);

final RegExp _integerPattern = RegExp(r'^-?[0-9]+$');

final RegExp _decimalPattern = RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)$');

/// A trailing UTC offset: "Z", "+07:00", "-0500".
final RegExp _offsetSuffixPattern = RegExp(
  r'(Z|[+-]\d{2}:?\d{2})$',
  caseSensitive: false,
);

extension StringExtensions on String? {
  /// Check if string is empty or contains only whitespace
  bool get isWhiteSpace {
    if (this == null) return true;
    return this!.trim().isEmpty;
  }

  /// Check if email is valid. The whole value must match: trailing text such
  /// as "john@mail.com) junk" is rejected.
  bool get isValidEmail {
    if (this == null) return false;
    return _emailPattern.hasMatch(this!.trim());
  }

  /// Check if password is valid (minimum 6 characters)
  bool get isValidPassword {
    if (this == null) return false;
    return this!.length >= 6;
  }

  /// Check if phone number is valid in +CCXXXXXXXXXX format (country code + 7-15 digits)
  bool get isValidPhone {
    if (this == null) return false;
    final phoneRegExp = RegExp(r'^\+\d{1,3}\d{7,15}$');
    return phoneRegExp.hasMatch(this!);
  }

  /// Check if string is a whole number (optional leading minus).
  bool get isValidNumber {
    if (this == null) return false;
    return _integerPattern.hasMatch(this!);
  }

  /// Check if string is a finite decimal number, such as `-3`, `2.5` or `.5`.
  bool get isValidDecimal {
    if (this == null) return false;
    final text = this!.trim();
    if (!_decimalPattern.hasMatch(text)) return false;
    return double.tryParse(text)?.isFinite ?? false;
  }

  /// Convert string to title case
  String get toTitleCases {
    if (this == null || this!.isEmpty) return this ?? '';
    return this!
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  /// Check if string is numeric (including decimals)
  bool get isNumeric {
    if (this == null) return false;
    return double.tryParse(this!) != null;
  }

  /// Capitalize first letter
  String get capitalize {
    if (this == null || this!.isEmpty) return this ?? '';
    return this![0].toUpperCase() + this!.substring(1);
  }

  /// Remove all whitespace
  String get removeWhitespace {
    if (this == null) return '';
    return this!.replaceAll(RegExp(r'\s+'), '');
  }

  String get toBegin {
    if (this == null || this!.isEmpty) return this ?? '';
    return toBeginningOfSentenceCase(this!) ?? this!;
  }
}

/// DateTime extensions for time conversion
extension DateTimeExtensions on DateTime? {
  /// Convert DateTime to TimeOfDay
  TimeOfDay? toTimeOfDay() {
    if (this == null) return null;
    return TimeOfDay(hour: this!.hour, minute: this!.minute);
  }
}

/// TimeOfDay extensions for datetime conversion
extension TimeOfDayExtensions on TimeOfDay? {
  /// Convert TimeOfDay to DateTime with current date
  DateTime? toDateTime() {
    if (this == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, this!.hour, this!.minute);
  }

  /// Convert TimeOfDay to DateTime with specific date
  DateTime? toDateTimeWithDate(DateTime date) {
    if (this == null) return null;
    return DateTime(date.year, date.month, date.day, this!.hour, this!.minute);
  }
}

/// Parses a timestamp that is UTC when it carries no offset. A value that
/// already has an offset ("...+07:00") is parsed as written. Appending "Z" to
/// it would produce an invalid string.
DateTime? dateTimeUtcFromJson(String? s) {
  if (s == null) return null;
  try {
    final text = s.trim();
    final hasOffset = _offsetSuffixPattern.hasMatch(text);
    return DateTime.parse(hasOffset ? text : '${text}Z').toLocal();
  } catch (_) {
    return null;
  }
}

DateTime? dateTimeOffsetFromJson(String? s) {
  if (s == null) {
    return null;
  } else {
    try {
      return DateTime.parse(s).toLocal();
    } catch (e) {
      return null;
    }
  }
}

String? dateTimeUtcToJson(DateTime? dt) => dt?.toUtc().toIso8601String();

/// Convert DateTime to ISO8601 string including local timezone offset
String? dateTimeToIsoWithTimezone(DateTime? dt) {
  if (dt == null) return null;
  final local = dt.toLocal();

  String two(int n) => n.toString().padLeft(2, '0');

  final year = local.year.toString().padLeft(4, '0');
  final month = two(local.month);
  final day = two(local.day);
  final hour = two(local.hour);
  final minute = two(local.minute);
  final second = two(local.second);
  final ms = local.millisecond.toString().padLeft(3, '0');

  final offset = local.timeZoneOffset;
  String offsetString;
  if (offset == Duration.zero) {
    offsetString = 'Z';
  } else {
    final sign = offset.isNegative ? '-' : '+';
    final h = offset.inHours.abs().toString().padLeft(2, '0');
    final m = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    offsetString = '$sign$h:$m';
  }

  return '$year-$month-${day}T$hour:$minute:$second.$ms$offsetString';
}
