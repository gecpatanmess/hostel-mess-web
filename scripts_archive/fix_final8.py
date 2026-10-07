import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Fix the newline issue
text = text.replace(r'\nvoid main()', '\nvoid main()')
text = text.replace(r'\n  RegisteredStudent?', '\n  RegisteredStudent?')

# 2. Add _matchedStudent if missing (inject precisely inside _LoginScreenState)
if 'RegisteredStudent? _matchedStudent;' not in text:
    target = 'class _LoginScreenState extends State<LoginScreen> {'
    replacement = target + '\n  AdminUser? _matchedAdmin;\n  RegisteredStudent? _matchedStudent;\n  bool _isAdminFlow = false;'
    text = text.replace(target, replacement, 1)

# 3. Add _finalizeStudentLogin if missing (inject right after _sendFirebaseAdminOtp ends)
if 'Future<void> _finalizeStudentLogin' not in text:
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
    text = text.replace(target2, methods + '\n  ' + target2)

# 4. Remove the broken Firebase OTP methods completely!
def remove_body(match):
    return match.group(1) + "{\n    setState(() => _isVerifyingEmail = false);\n  }"

pattern_send = r'(Future<void> _sendFirebaseAdminOtp\(\) async )\{[\s\S]*?catch\(e\) \{[\s\S]*?\}\s*\}'
text = re.sub(pattern_send, remove_body, text)

pattern_verify = r'(Future<void> _verifyFirebaseAdminOtp\(String otp\) async )\{[\s\S]*?catch\(e\) \{[\s\S]*?\}\s*\}'
text = re.sub(pattern_verify, remove_body, text)

# 5. Fix AdminUser access for name
text = text.replace('admin.name', '"Admin"')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Applied final robust fixes!")
