import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# I will inject it before `_handleStudentLogin`
forgot_pwd_code = """
  Future<void> _handleForgotPassword(bool isStudentReq) async {
    String? emailToSend;
    if (isStudentReq) {
      if (savedStudentName == null) return;
      var roomStudents = globalRegisteredStudents.where((s) => s.roomNo == savedStudentRoom).toList();
      try {
        var existingStudent = roomStudents.firstWhere((s) => s.name.toLowerCase() == savedStudentName!.toLowerCase());
        emailToSend = existingStudent.email;
      } catch (e) {}
    } else {
      if (savedAdminPhone == null) return;
      try {
        var admin = globalAdmins.firstWhere((a) => a.phone == savedAdminPhone);
        emailToSend = admin.email;
      } catch(e) {}
    }
    
    if (emailToSend == null || emailToSend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email found for this account.'), backgroundColor: Colors.redAccent));
      return;
    }
    
    bool verified = await showOtpVerificationDialog(context, emailToSend);
    if (verified) {
      // Let them reset the password
      TextEditingController newPassCtrl = TextEditingController();
      TextEditingController rePassCtrl = TextEditingController();
      bool resetDone = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Reset Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: newPassCtrl, decoration: const InputDecoration(hintText: "Enter 8-digit new password")),
              const SizedBox(height: 10),
              TextField(controller: rePassCtrl, decoration: const InputDecoration(hintText: "Re-enter password")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (newPassCtrl.text.length < 8) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Password must be 8 characters")));
                  return;
                }
                if (newPassCtrl.text != rePassCtrl.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text("Save"),
            )
          ],
        )
      ) ?? false;
      
      if (resetDone) {
        if (isStudentReq) {
          var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name.toLowerCase() == savedStudentName!.toLowerCase());
          existingStudent.pin = newPassCtrl.text;
          await saveRegisteredStudents();
          SyncService.pushStudents();
        } else {
          var admin = globalAdmins.firstWhere((a) => a.phone == savedAdminPhone);
          admin.pin = newPassCtrl.text;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('globalAdmins', globalAdmins.map((a) => jsonEncode(a.toJson())).toList());
          SyncService.pushAdmins();
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset successfully!"), backgroundColor: Colors.green));
      }
    }
  }

  void _handleStudentLogin() async {"""

code = code.replace("  void _handleStudentLogin() async {", forgot_pwd_code)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Patching logic part 3 complete")
