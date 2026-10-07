import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // Remove from Student
  String targetRemove = '''
  void _onLogout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  void _closeMessAndMarkAbsent(String meal) {
    DateTime now = DateTime.now();
    for (var s in globalRegisteredStudents) {
      String key = "\${now.year}-\${now.month}-\${now.day}_\${s.roomNo}_\${s.name}";
      if (globalAttendanceMap[key] == null) {
        globalAttendanceMap[key] = DailyRecord();
      }
      if (meal == 'l' && globalAttendanceMap[key]!.l == '-') {
        globalAttendanceMap[key]!.l = 'A';
      } else if (meal == 'd' && globalAttendanceMap[key]!.d == '-') {
        globalAttendanceMap[key]!.d = 'A';
      }
    }
  }
''';
  
  String replacementRemove = '''
  void _onLogout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
''';
  
  content = content.replaceFirst(targetRemove, replacementRemove);

  // Add to Admin
  // Since _onLogout appears twice, we will replace the LAST occurrence, which is the admin one.
  int lastIndex = content.lastIndexOf('void _onLogout() {');
  
  String before = content.substring(0, lastIndex);
  String after = content.substring(lastIndex);
  
  String newAfter = after.replaceFirst('''
  void _onLogout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
''', '''
  void _onLogout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  void _closeMessAndMarkAbsent(String meal) {
    DateTime now = DateTime.now();
    for (var s in globalRegisteredStudents) {
      String key = "\${now.year}-\${now.month}-\${now.day}_\${s.roomNo}_\${s.name}";
      if (globalAttendanceMap[key] == null) {
        globalAttendanceMap[key] = DailyRecord();
      }
      if (meal == 'l' && globalAttendanceMap[key]!.l == '-') {
        globalAttendanceMap[key]!.l = 'A';
      } else if (meal == 'd' && globalAttendanceMap[key]!.d == '-') {
        globalAttendanceMap[key]!.d = 'A';
      }
    }
  }
''');

  content = before + newAfter;
  
  file.writeAsStringSync(content);
}
