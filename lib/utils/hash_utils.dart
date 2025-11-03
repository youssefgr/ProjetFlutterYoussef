import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;

String md5Hex(Uint8List bytes) {
  final digest = crypto.md5.convert(bytes);
  return digest.toString();
}
