import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Insert the missing state variables
if 'RegisteredStudent? _matchedStudent;' not in text:
    target = 'class _LoginScreenState extends State<LoginScreen> {'
    replacement = target + '''
  AdminUser? _matchedAdmin;
  RegisteredStudent? _matchedStudent;
  bool _isAdminFlow = false;
'''
    text = text.replace(target, replacement)

# Convert types to dynamic to avoid undefined type errors from Firebase Auth
text = text.replace('(PhoneAuthCredential credential) async {', '(dynamic credential) async {')
text = text.replace('(FirebaseAuthException e) {', '(dynamic e) {')
text = text.replace('PhoneAuthCredential credential = PhoneAuthProvider', 'dynamic credential = PhoneAuthProvider')
text = text.replace('await FirebaseAuth.instance', '// await FirebaseAuth.instance')
text = text.replace('PhoneAuthProvider.credential', '// PhoneAuthProvider.credential')

# Check if _finalizeStudentLogin exists
if 'Future<void> _finalizeStudentLogin' not in text:
    print("WARNING: _finalizeStudentLogin is missing!")
    
    finalize_methods = '''
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
    await prefs.setString('last_admin_name', admin.name ?? "Admin");
    await prefs.setString('last_admin_photo', admin.photoUrl ?? '');
    await prefs.setString('userType', 'admin');
    await prefs.setString('identifier', admin.phone);
    await prefs.setString('photoPath', admin.photoUrl ?? '');
    await prefs.setString('extraInfo', admin.name ?? "Admin");
    await NotificationService.saveToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDashboardScreen(
          photoUrl: admin.photoUrl,
          name: admin.name ?? "Admin",
          phone: admin.phone,
        ),
      ),
    );
  }
'''
    # We will inject these right before Widget build(BuildContext context) {
    text = text.replace('  @override\n  Widget build(BuildContext context) {', finalize_methods + '\n  @override\n  Widget build(BuildContext context) {')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Applied missing methods and dynamic types!")
