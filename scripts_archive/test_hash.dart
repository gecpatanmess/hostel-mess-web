import 'dart:convert';
import 'package:crypto/crypto.dart';
void main() {
  var bytes = utf8.encode("dax123");
  var digest = sha256.convert(bytes);
  print("dax123 => $digest");
  var bytes2 = utf8.encode("asdfg lkjh zxcvb mn");
  var digest2 = sha256.convert(bytes2);
  print("asdfg lkjh zxcvb mn => $digest2");
}
