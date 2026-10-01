import 'dart:io';

void main() {
  var lines = File('lib/main.dart').readAsLinesSync();
  for(int i = 2890; i < 2910; i++) {
     print("${i+1}: ${lines[i]}");
  }
}
