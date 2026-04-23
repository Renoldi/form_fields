/// Exception for validation warning (not fail/error)
class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? details;
  ValidationException(this.message, {this.details});
  @override
  String toString() => message;
}
