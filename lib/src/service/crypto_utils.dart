import 'dart:io';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  CryptoUtils._();
  static final CryptoUtils instance = CryptoUtils._();

  Future<String> fileSha256(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Compute SHA-256 for an in-memory byte sequence.
  String bytesSha256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Compute SHA-256 for a file by streaming its bytes to avoid loading
  /// the entire file into memory. Useful for large payload files.
  Future<String> fileSha256Stream(File file) async {
    // Use a small sink to capture the resulting Digest from the hasher.
    Digest? result;
    final digestSink = _DigestCaptureSink((d) => result = d);
    final sink = sha256.startChunkedConversion(digestSink);
    await for (final chunk in file.openRead()) {
      sink.add(chunk);
    }
    sink.close();
    return result!.toString();
  }
}

class _DigestCaptureSink implements Sink<Digest> {
  final void Function(Digest) _onDigest;
  _DigestCaptureSink(this._onDigest);
  @override
  void add(Digest data) => _onDigest(data);
  @override
  void close() {}
}
