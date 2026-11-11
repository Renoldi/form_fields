import 'dart:convert';
import 'dart:typed_data';

/// Decodes image bytes from a base64 string. The string may be plain base64
/// or a `data:<mime>;base64,` URI, and whitespace inside it is ignored.
///
/// Returns null for empty, malformed or non-base64 input. `Uri.parse` cannot
/// do this job, because a plain base64 string has no `data:` scheme for it to
/// read.
Uint8List? decodeBase64Image(String value) {
  var raw = value.trim();
  if (raw.isEmpty) return null;
  if (raw.startsWith('data:')) {
    final comma = raw.indexOf(',');
    if (comma < 0) return null;
    raw = raw.substring(comma + 1);
  }
  raw = raw.replaceAll(RegExp(r'\s+'), '');
  if (raw.isEmpty) return null;
  try {
    final bytes = base64Decode(raw);
    return bytes.isEmpty ? null : bytes;
  } on FormatException {
    return null;
  }
}
