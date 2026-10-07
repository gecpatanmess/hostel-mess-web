import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var code = file.readAsStringSync();

  // Add isValid getter to RegisteredStudent
  if (!code.contains('bool get isValid')) {
    code = code.replaceAll(
      'email: parseStr(json[' + "'email'" + ']),\n    );\n  }',
      'email: parseStr(json[' + "'email'" + ']),\n    );\n  }\n  bool get isValid => name.isNotEmpty && roomNo.isNotEmpty;'
    );
  }

  // Update line 1078 (approximately)
  code = code.replaceAll(
    'globalRegisteredStudents = studentStrs.map((s) => RegisteredStudent.fromJson(jsonDecode(s))).toList();',
    'globalRegisteredStudents = studentStrs.map((s) => RegisteredStudent.fromJson(jsonDecode(s))).where((s) => s.isValid).toList();'
  );

  // Update .add(RegisteredStudent.fromJson(Map<String,dynamic>.from(s)))
  code = code.replaceAll(
    'globalRegisteredStudents.add(RegisteredStudent.fromJson(Map<String,dynamic>.from(s)));',
    'var st = RegisteredStudent.fromJson(Map<String,dynamic>.from(s));\n              if (st.isValid) globalRegisteredStudents.add(st);'
  );

  file.writeAsStringSync(code);
  print('Done!');
}
