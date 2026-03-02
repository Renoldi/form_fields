/// Enum defining where error messages should be displayed on screen.
enum ErrorPosition {
  /// Display error at the top of the screen
  top,

  /// Display error in the center of the screen
  center,

  /// Display error at the bottom of the screen
  bottom,
}

/// Extension to add utility methods to ErrorPosition
extension ErrorPositionExtension on ErrorPosition {
  /// Get the string representation of the error position
  String get label {
    switch (this) {
      case ErrorPosition.top:
        return 'Top';
      case ErrorPosition.center:
        return 'Center';
      case ErrorPosition.bottom:
        return 'Bottom';
    }
  }

  /// Convert string to ErrorPosition
  static ErrorPosition fromString(String value) {
    return ErrorPosition.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ErrorPosition.top,
    );
  }

  /// Convert ErrorPosition to string for storage
  String toStorageString() => toString().split('.').last;
}
