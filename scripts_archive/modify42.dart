import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  String target1 = '''
  void _onLogout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
''';

  String replacement1 = '''
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

  content = content.replaceFirst(target1, replacement1);

  file.writeAsStringSync(content);
}
