import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll("    globalPollB = false;\n", "");
  content = content.replaceAll("rec.b = b; rec.l = l; rec.d = d;", "rec.l = l; rec.d = d;");
  content = content.replaceAll("if (rec.b == 'P') total += 20;\n", "");
  
  file.writeAsStringSync(content);
}
