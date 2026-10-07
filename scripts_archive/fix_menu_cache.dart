import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // Replace the static filename with a unique one to break image cache
  content = content.replaceFirst(
    "File mFile = File('\${dir.path}/mess_menu.\$ext');",
    "File mFile = File('\${dir.path}/mess_menu_\${DateTime.now().millisecondsSinceEpoch}.\$ext');"
  );
  
  file.writeAsStringSync(content);
}
