import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  var bytes = utf8.encode('12345678');
  var digest = sha256.convert(bytes);
  print(digest.toString());
}
