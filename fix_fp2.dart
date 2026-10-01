import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  content = content.replaceFirst('FilePicker.platform.pickFiles', 'FilePicker.pickFiles');
  file.writeAsStringSync(content);
}
