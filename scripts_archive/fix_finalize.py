import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

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

  Future<void> _finalizeAdminLogin(AdminUser admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_admin_phone', admin.phone);
    await prefs.setString('last_admin_name', admin.name);
    await prefs.setString('last_admin_photo', admin.photoUrl ?? '');
    await prefs.setString('userType', 'admin');
    await prefs.setString('identifier', admin.phone);
    await prefs.setString('photoPath', admin.photoUrl ?? '');
    await prefs.setString('extraInfo', admin.name);
    await NotificationService.saveToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDashboardScreen(
          photoUrl: admin.photoUrl,
          name: admin.name,
          phone: admin.phone,
        ),
      ),
    );
  }

'''

text = text.replace('  Widget _buildStudentPortal() {', methods + '  Widget _buildStudentPortal() {')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Re-added finalize methods.")
