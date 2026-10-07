with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace _finalizeStudentLogin
old_s = """  Future<void> _finalizeStudentLogin(RegisteredStudent student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_student_name', student.name);
    await prefs.setString('last_student_room', student.roomNo);
    await prefs.setString('last_student_photo', student.photoUrl ?? '');
    await prefs.setString('userType', 'student');
    await prefs.setString('identifier', student.name);
    await prefs.setString('photoPath', student.photoUrl ?? '');
    await prefs.setString('extraInfo', student.roomNo);
    await NotificationService.saveToken();

    Navigator.pushReplacement("""
    
new_s = """  Future<void> _finalizeStudentLogin(RegisteredStudent student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_student_name', student.name);
    await prefs.setString('last_student_room', student.roomNo);
    await prefs.setString('last_student_photo', student.photoUrl ?? '');
    await prefs.setString('userType', 'student');
    await prefs.setString('identifier', student.name);
    await prefs.setString('photoPath', student.photoUrl ?? '');
    await prefs.setString('extraInfo', student.roomNo);
    
    // CRITICAL FIX: Restart streams for the correct hostel mode before navigating
    await SyncService.switchMode(globalHostelMode);
    
    await NotificationService.saveToken();

    Navigator.pushReplacement("""

# Replace _finalizeAdminLogin
old_a = """  Future<void> _finalizeAdminLogin(AdminUser admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_admin_phone', admin.phone);
    await prefs.setString('last_admin_name', admin.name);
    await prefs.setString('last_admin_photo', admin.photoUrl ?? '');
    await prefs.setString('userType', 'admin');
    await prefs.setString('identifier', admin.phone);
    await prefs.setString('photoPath', admin.photoUrl ?? '');
    await prefs.setString('extraInfo', admin.name);
    await NotificationService.saveToken();
    Navigator.pushReplacement("""

new_a = """  Future<void> _finalizeAdminLogin(AdminUser admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_admin_phone', admin.phone);
    await prefs.setString('last_admin_name', admin.name);
    await prefs.setString('last_admin_photo', admin.photoUrl ?? '');
    await prefs.setString('userType', 'admin');
    await prefs.setString('identifier', admin.phone);
    await prefs.setString('photoPath', admin.photoUrl ?? '');
    await prefs.setString('extraInfo', admin.name);
    
    // CRITICAL FIX: Restart streams for the correct hostel mode before navigating
    await SyncService.switchMode(globalHostelMode);
    
    await NotificationService.saveToken();
    Navigator.pushReplacement("""

code = code.replace(old_s, new_s)
code = code.replace(old_a, new_a)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print('Login sync mode fixed!')
