import 'enums.dart';
import 'validation_exception.dart';

/// Error mapper to distinguish between warning (validation) and fail (error)
/// Use in guard: mapError: customErrorMapper
/// Throws [ValidationException] for validation warning.
({String message, AppDialogType type}) customErrorMapper(Object error) {
  if (error is ValidationException) {
    return (message: error.message, type: AppDialogType.validation);
  }
  // Add more custom error mapping as needed
  return (message: error.toString(), type: AppDialogType.server);
}
