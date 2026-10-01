import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll("}\\n\\n  Widget _buildPollCard", "}  Widget _buildPollCard");
  
  file.writeAsStringSync(content);
}
