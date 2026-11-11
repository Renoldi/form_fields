import 'dart:io';

/// Returns [headers] without credentials, for an upload payload that is kept
/// for a later retry (offline queue, `onFailDirectUploadPayload`).
///
/// A persisted payload must not hold a bearer token. Callers supply a fresh one
/// when they retry, through `uploadTokenRefresher`.
Map<String, String> headersForPersistence(Map<String, String> headers) {
  final copy = Map<String, String>.of(headers);
  copy.removeWhere(
    (key, _) => key.toLowerCase() == HttpHeaders.authorizationHeader,
  );
  return copy;
}
