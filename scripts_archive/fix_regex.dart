import 'dart:io';
void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(RegExp(r'setState\(\(\) \{\s*if \(mealType == \x27L\x27\) \{\s*rec.l = \(rec.l == \x27P\x27\) \? \x27A\x27 : \x27P\x27;\s*\} else \{\s*rec.d = \(rec.d == \x27P\x27\) \? \x27A\x27 : \x27P\x27;\s*\}\s*globalAttendanceMap\[key\] = rec;\s*await SyncService.pushAttendance\(key, rec\);\s*(setState\(\(\) \{\},\s*\);\s*\/\/[^\n]+)?\}\);'),
  '''if (mealType == 'L') {
    rec.l = (rec.l == 'P') ? 'A' : 'P';
  } else {
    rec.d = (rec.d == 'P') ? 'A' : 'P';
  }
  globalAttendanceMap[key] = rec;
  await SyncService.pushAttendance(key, rec);
  setState(() {});''');
  file.writeAsStringSync(content);
}
