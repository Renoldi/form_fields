/// String extensions for validation and manipulation
import 'package:flutter/material.dart';

extension StringExtensions on String? {
  /// Check if string is empty or contains only whitespace
  bool get isWhiteSpace {
    if (this == null) return true;
    return this!.trim().isEmpty;
  }

  /// Check if email is valid
  bool get isValidEmail {
    if (this == null) return false;
    final emailRegExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    return emailRegExp.hasMatch(this!);
  }

  /// Check if password is valid (minimum 6 characters)
  bool get isValidPassword {
    if (this == null) return false;
    return this!.length >= 6;
  }

  /// Check if phone number is valid (Indonesian format: +0 followed by 11 digits)
  bool get isValidPhone {
    if (this == null) return false;
    final phoneRegExp = RegExp(r"^\+?0[0-9]{11}$");
    return phoneRegExp.hasMatch(this!);
  }

  /// Check if string is a valid number
  bool get isValidNumber {
    if (this == null) return false;
    final phoneRegExp = RegExp(r'^-?[0-9]+$');
    return phoneRegExp.hasMatch(this!);
  }

  /// Convert string to title case
  String get toTitleCase {
    if (this == null || this!.isEmpty) return this ?? '';
    return this!
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
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
