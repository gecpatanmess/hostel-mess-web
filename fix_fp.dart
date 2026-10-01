import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  content = content.replaceFirst('FilePicker.platform.pickFiles', 'FilePicker.platform?.pickFiles');
  // Wait, if 'platform' doesn't exist at all, even '?' won't help.
}
