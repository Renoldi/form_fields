import 'dart:io';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  CryptoUtils._();
  static final CryptoUtils instance = CryptoUtils._();

  Future<String> fileSha256(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}
