import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll("const ViewMenuTab()", "ViewMenuTab()");
  
  file.writeAsStringSync(content);
}
