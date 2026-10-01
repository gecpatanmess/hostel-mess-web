import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  String target1 = '''
  void _logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
''';

  String replacement1 = '''
  void _logout() {
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

  String target2 = '''
                SwitchListTile(
                  title: const Text('Lunch'),
                  activeColor: brandOrange,
                  value: globalEntryL,
                  onChanged: (v) => setState(() => globalEntryL = v),
                ),
                SwitchListTile(
                  title: const Text('Dinner'),
                  activeColor: brandOrange,
                  value: globalEntryD,
                  onChanged: (v) => setState(() => globalEntryD = v),
                ),
''';

  String replacement2 = '''
                SwitchListTile(
                  title: const Text('Lunch'),
                  activeColor: brandOrange,
                  value: globalEntryL,
                  onChanged: (v) {
                    setState(() => globalEntryL = v);
                    if (v == false) {
                      _closeMessAndMarkAbsent('l');
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Dinner'),
                  activeColor: brandOrange,
                  value: globalEntryD,
                  onChanged: (v) {
                    setState(() => globalEntryD = v);
                    if (v == false) {
                      _closeMessAndMarkAbsent('d');
                    }
                  },
                ),
''';

  content = content.replaceFirst(target2, replacement2);

  file.writeAsStringSync(content);
}
