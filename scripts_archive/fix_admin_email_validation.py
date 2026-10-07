with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

target = """    }

    final email = isStudentForm
        ? _studentEmailController.text.trim()
        : _adminEmailController.text.trim();"""

replacement = """    } else if (!isStudentForm && !hasSavedAdmin) {
      if (_adminMobileController.text.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit mobile number.'), backgroundColor: Colors.redAccent));
        return;
      }
      if (_adminNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name.'), backgroundColor: Colors.redAccent));
        return;
      }
      if (_adminPasswordController.text.length != 8) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be exactly 8 characters.'), backgroundColor: Colors.redAccent));
        return;
      }
      if (adminPhotoUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a photo.'), backgroundColor: Colors.redAccent));
        return;
      }
      // Check if admin exists and password matches
      String phone = _adminMobileController.text.trim();
      String pin = _adminPasswordController.text;
      AdminUser? admin;
      try {
        admin = globalAdmins.firstWhere((a) => a.phone == phone);
      } catch (e) {
        admin = null;
      }
      if (admin == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin account not found. Please contact super admin.'), backgroundColor: Colors.redAccent));
        return;
      } else {
        if (admin.pin != hashPassword(pin) && admin.pin != pin) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password!'), backgroundColor: Colors.redAccent));
          return;
        }
      }
    }

    final email = isStudentForm
        ? _studentEmailController.text.trim()
        : _adminEmailController.text.trim();"""

if target in code:
    code = code.replace(target, replacement)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Replaced admin validation successfully!")
else:
    print("Could not find the target code.")
