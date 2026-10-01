import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

student_gate = '''    // Email verification check
    if (!hasSavedStudent && !_studentEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email first by clicking "Verify"'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    String typedName = selectedStudentName!;'''

code = code.replace("    String typedName = selectedStudentName!;", student_gate)

admin_gate = '''    // Email verification check
    if (!hasSavedAdmin && !_adminEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email first by clicking "Verify"'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    String typedName = _adminNameController.text.trim();'''

code = code.replace("    String typedName = _adminNameController.text.trim();", admin_gate)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Gates applied!")
