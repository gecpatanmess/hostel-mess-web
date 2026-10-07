import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  String oldStr = 'String dateStr = "\\\${selectedDate.day.toString().padLeft(2,\\\'0\\\')}/\\\${selectedDate.month.toString().padLeft(2,\\\'0\\\')}";';
  String newStr = 'String dateStr = "\\\${selectedDate.day.toString().padLeft(2,\\\'0\\\')}/\\\${selectedDate.month.toString().padLeft(2,\\\'0\\\')}/\\\${selectedDate.year}";';

  content = content.replaceFirst(oldStr, newStr);

  file.writeAsStringSync(content);
}
