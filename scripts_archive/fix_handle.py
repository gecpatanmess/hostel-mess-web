import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

handle_old = '''  Future<void> _handleForgotPassword(bool isStudentReq) async {
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
    }'''

handle_new = '''  Future<void> _handleForgotPassword(bool isStudentReq) async {
    String? emailToSend;
    String? targetIdentifier;
    
    if (isStudentReq) {
      targetIdentifier = hasSavedStudent ? savedStudentName : selectedStudentName;
      if (targetIdentifier == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your name first.")));
        return;
      }
      try {
        var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name == targetIdentifier);
        emailToSend = existingStudent.email;
      } catch (e) {}
    } else {
      targetIdentifier = hasSavedAdmin ? savedAdminPhone : _adminMobileController.text.trim();
      if (targetIdentifier == null || targetIdentifier.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your mobile number first.")));
        return;
      }
      try {
        var admin = globalAdmins.firstWhere((a) => a.phone == targetIdentifier);
        emailToSend = admin.email;
      } catch(e) {}
    }'''

code = code.replace(handle_old, handle_new)

reset_old = '''              if (newPassCtrl.text == rePassCtrl.text && newPassCtrl.text.length >= 8) {
                if (isStudentReq) {
                  var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name == savedStudentName);
                  existingStudent.pin = newPassCtrl.text;
                  SyncService.pushStudents();
                } else {
                  var admin = globalAdmins.firstWhere((a) => a.phone == savedAdminPhone);
                  admin.pin = newPassCtrl.text;
                  SyncService.pushAdmins();
                }'''

reset_new = '''              if (newPassCtrl.text == rePassCtrl.text && newPassCtrl.text.length >= 8) {
                if (isStudentReq) {
                  var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name == targetIdentifier);
                  existingStudent.pin = hashPassword(newPassCtrl.text);
                  SyncService.pushStudents();
                } else {
                  var admin = globalAdmins.firstWhere((a) => a.phone == targetIdentifier);
                  admin.pin = hashPassword(newPassCtrl.text);
                  SyncService.pushAdmins();
                }'''
code = code.replace(reset_old, reset_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Applied fix for _handleForgotPassword logic.")
