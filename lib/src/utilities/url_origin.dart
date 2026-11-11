/// True when [url] has the same scheme, host and port as [origin].
///
/// Used to decide whether a credential may be sent to [url]. A link in a server
/// response can point anywhere, and the upload token must reach only the server
/// that issued it. Relative or unparsable values are never considered the same.
bool isSameOrigin(String url, String? origin) {
  if (origin == null || origin.trim().isEmpty) return false;
  final a = Uri.tryParse(url.trim());
  final b = Uri.tryParse(origin.trim());
  if (a == null || b == null || !a.hasScheme || !b.hasScheme) return false;
  if (!a.hasAuthority || !b.hasAuthority) return false;
  return a.scheme == b.scheme && a.host == b.host && a.port == b.port;
}
