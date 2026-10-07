import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

# Add pushAdmins to SyncService
old_push_students = """    static Future<void> pushStudents() async {
      try {
        List<Map<String, dynamic>> studentsList = [];
        for(var s in globalRegisteredStudents) {
          studentsList.add(s.toJson());
        }
        await _dbRef.child('students').set(studentsList);
      } catch(e){}
    }"""
new_push_students = """    static Future<void> pushStudents() async {
      try {
        List<Map<String, dynamic>> studentsList = [];
        for(var s in globalRegisteredStudents) {
          studentsList.add(s.toJson());
        }
        await _dbRef.child('students').set(studentsList);
      } catch(e){}
    }

    static Future<void> pushAdmins() async {
      try {
        List<Map<String, dynamic>> adminsList = [];
        for(var a in globalAdmins) {
          adminsList.add(a.toJson());
        }
        await _dbRef.child('admins').set(adminsList);
      } catch(e){}
    }"""

code = code.replace(old_push_students, new_push_students)

# Update _handleAdminLogin
old_admin_login = """          if (admin.pin == pin) {
            // Success
            if (!hasSavedAdmin && _adminEmailController.text.isNotEmpty) {
              admin.email = _adminEmailController.text.trim();
            }
            final prefs = await SharedPreferences.getInstance();"""

new_admin_login = """          if (admin.pin == pin) {
            // Success
            if (!hasSavedAdmin && _adminEmailController.text.isNotEmpty) {
              admin.email = _adminEmailController.text.trim();
              SyncService.pushAdmins();
            }
            final prefs = await SharedPreferences.getInstance();"""

code = code.replace(old_admin_login, new_admin_login)

with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
