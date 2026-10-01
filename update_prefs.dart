import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  // 1. Update _loadDataFromPrefs
  content = content.replaceFirst(
    '''
  if (adminStrs != null && adminStrs.isNotEmpty) {
    globalAdmins = adminStrs.map((s) => AdminUser.fromJson(jsonDecode(s))).toList();
  }
''',
    '''
  if (adminStrs != null && adminStrs.isNotEmpty) {
    globalAdmins = adminStrs.map((s) => AdminUser.fromJson(jsonDecode(s))).toList();
  }
  
  List<String>? studentStrs = prefs.getStringList('globalRegisteredStudents');
  if (studentStrs != null && studentStrs.isNotEmpty) {
    // If we have saved students, overwrite the fake ones completely
    globalRegisteredStudents = studentStrs.map((s) => RegisteredStudent.fromJson(jsonDecode(s))).toList();
  }
'''
  );

  // 2. Update _handleStudentLogin to call saveRegisteredStudents
  content = content.replaceFirst(
    '''
      if (studentPhoto == null) {
        studentPhoto = existingStudent.photo;
      } else {
        existingStudent.photo = studentPhoto!;
      }
''',
    '''
      if (studentPhoto == null) {
        studentPhoto = existingStudent.photo;
      } else {
        existingStudent.photo = studentPhoto!;
      }
      await saveRegisteredStudents();
'''
  );

  File('lib/main.dart').writeAsStringSync(content);
}
