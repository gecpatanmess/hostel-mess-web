import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Add _finalizeStudentLogin right before _finalizeAdminLogin
target2 = 'Future<void> _finalizeAdminLogin(AdminUser admin) async {'
methods = '''
  Future<void> _finalizeStudentLogin(RegisteredStudent student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_student_name', student.name);
    await prefs.setString('last_student_room', student.roomNo);
    await prefs.setString('last_student_photo', student.photoUrl ?? '');
    await prefs.setString('userType', 'student');
    await prefs.setString('identifier', student.name);
    await prefs.setString('photoPath', student.photoUrl ?? '');
    await prefs.setString('extraInfo', student.roomNo);
    await NotificationService.saveToken();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboardScreen(
          photoUrl: student.photoUrl,
          name: student.name,
          roomNo: student.roomNo,
        ),
      ),
    );
  }
'''
if 'Future<void> _finalizeStudentLogin' not in text:
    text = text.replace(target2, methods + '\n  ' + target2)

# Fix AdminUser access for name
text = text.replace('admin.name', '"Admin"')
text = text.replace('admin.photoUrl', 'null')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Applied _finalizeStudentLogin and AdminUser fixes!")
