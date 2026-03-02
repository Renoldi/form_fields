/// Enum defining types of errors that can be displayed to the user.
enum ErrorType {
  /// Validation errors (e.g., required fields, format)
  validation,

  /// Network errors (e.g., no internet, timeout)
  network,

  /// Authentication errors (e.g., invalid credentials)
  authentication,

  /// Server errors (e.g., 500, server not responding)
  server,
}

/// Extension to add utility methods to ErrorType
extension ErrorTypeExtension on ErrorType {
  /// Get the display label for this error type
  String get label {
    switch (this) {
      case ErrorType.validation:
        return 'Validation Error';
      case ErrorType.network:
        return 'Network Error';
      case ErrorType.authentication:
        return 'Authentication Error';
      case ErrorType.server:
        return 'Server Error';
    }
  }

  /// Convert string to ErrorType
  static ErrorType fromString(String value) {
    return ErrorType.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ErrorType.server,
    );
  }

  /// Convert ErrorType to string for storage
  String toStorageString() => toString().split('.').last;
}
