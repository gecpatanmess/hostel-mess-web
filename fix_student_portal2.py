import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Fix Student Login Logic
student_login_old = '''    // Email verification check
    if (!_studentEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email first by clicking "Verify Email"'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }'''

student_login_new = '''    // Email verification check
    if (!hasSavedStudent && !_studentEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email first by clicking "Verify Email"'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }'''
code = code.replace(student_login_old, student_login_new)

# 2. Fix Admin Login Logic
admin_login_old = '''    // Email verification check for admin
    if (!_adminEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please verify your email first by clicking "Verify Email"',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }'''

admin_login_new = '''    // Email verification check for admin
    if (!hasSavedAdmin && !_adminEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please verify your email first by clicking "Verify Email"',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }'''
code = code.replace(admin_login_old, admin_login_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Login logic fixed")
