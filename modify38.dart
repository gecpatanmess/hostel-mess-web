import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // 1. Change main() to call _loadFakeStudents()
  String mainTarget = '''
void main() {
  runApp(const MyApp());
}
''';
  String mainReplacement = '''
void main() {
  _loadFakeStudents();
  runApp(const MyApp());
}
''';
  content = content.replaceFirst(mainTarget, mainReplacement);

  // 2. Remove loadSampleAttendanceData definition and its usage
  String callTarget = '''
    // Load sample data for testing (REMOVE LATER)
    loadSampleAttendanceData(selectedRoom!, typedName);
''';
  content = content.replaceFirst(callTarget, '');

  file.writeAsStringSync(content);
}
