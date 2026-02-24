/// Extensions for String and DateTime utilities used in FormFields package
import 'package:intl/intl.dart';

enum Formats { date, dayDate, time, dayDateTime, dateTime, month, string }

/// Extensions for DateTime
extension ExtDate on DateTime? {
  /// Check if this DateTime is before another
  bool isBefore(DateTime? other) {
    if (this == null) {
      return false;
    } else {
      return this!.isBefore(other ?? DateTime.now());
    }
  }

  /// Check if this DateTime is after another
  bool isAfter(DateTime? other) {
    if (this == null) {
      return false;
    } else {
      return this!.isAfter(other ?? DateTime.now());
    }
  }

  /// Check if this DateTime is at the same moment as another
  bool isAtSameMomentAs(DateTime? other) {
    if (this == null) {
      return false;
    } else {
      return this!.isAtSameMomentAs(other ?? DateTime.now());
    }
  }

  /// Convert DateTime to formatted string
  String toStrings({Formats format = Formats.date, String stringFormat = ""}) {
    if (this == null) {
      return "";
    } else {
      if (format == Formats.string) {
        if (stringFormat.isNotEmpty) {
          return DateFormat(stringFormat).format(this!);
        } else {
          return DateFormat.Hm().format(this!);
        }
      } else if (format == Formats.date) {
        return DateFormat.yMMMd().format(this!);
      } else if (format == Formats.dayDate) {
        return DateFormat.E().add_yMd().format(this!);
      } else if (format == Formats.dayDateTime) {
        return DateFormat.E().add_yMd().add_Hm().format(this!);
      } else if (format == Formats.dateTime) {
        return DateFormat.yMMMd().add_Hm().format(this!);
      } else if (format == Formats.time) {
        return DateFormat.Hm().format(this!);
      } else if (format == Formats.month) {
        return DateFormat.MMM().format(this!);
      } else {
        return DateFormat.yMMMd().format(this!);
      }
    }
  }
}

/// Extensions for String validation and manipulation
extension ExtString on String {
  /// Check if email is valid
  bool get isValidEmail {
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(this);
  }

  /// Check if string is whitespace or empty
  bool get isWhiteSpace => trim().isEmpty;

  /// Check if password is valid (minimum 6 characters)
  bool get isValidPassword => length > 5;

  /// Check if string is a valid verification code
  bool get isValidVerification => length >= 1;

  /// Hide phone number (show only last 4 digits)
  String get hidePhone {
    List<String> result = split("");
    String phone = "";
    int leftChar = 4;
    int t = result.length - leftChar;
    int n = 1;
    for (var e in result) {
      if (n > t) {
        phone += e;
      } else {
        phone += "*";
      }
      n++;
    }
    return phone;
  }

  /// Add leading zero if phone doesn't start with 0
  String get is0Phone {
    String p = "";
    if (isNotEmpty && substring(0, 1) != "0") {
      p += "0$this";
    } else {
      p = this;
    }
    return p;
  }

  /// Check if phone number is valid (Indonesian format: +0 followed by 11 digits)
  bool get isValidPhone {
    final phoneRegExp = RegExp(r"^\+?0[0-9]{11}$");
    return phoneRegExp.hasMatch(this);
  }

  /// Check if string is a valid number
  bool get isValidNumber {
    final phoneRegExp = RegExp(r'^-?[0-9]+$');
    return phoneRegExp.hasMatch(this);
  }

  /// Convert string to title case
  String get toTitleCase {
    if (length <= 1) {
      return toUpperCase();
    }
    final List<String> words = split(' ');

    final capitalizedWords = words.map((word) {
      if (word.trim().isNotEmpty) {
        final String firstLetter = word.trim().substring(0, 1).toUpperCase();
        final String remainingLetters = word.trim().substring(1);

        return '$firstLetter$remainingLetters';
      }
      return '';
    });

    return capitalizedWords.join(' ');
  }
}
