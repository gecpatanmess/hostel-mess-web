import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var lines = file.readAsLinesSync();
  
  if (lines[2856].trim() == ')') {
      lines[2856] = lines[2856] + ',';
  }
  
  if (lines[2859].trim() == '),') {
      lines[2859] = '';
  }
  
  if (lines[2931].contains(');// ---')) {
      lines[2931] = lines[2931].replaceAll(');// ---', ');\n// ---');
  }

  file.writeAsStringSync(lines.join('\n'));
}
