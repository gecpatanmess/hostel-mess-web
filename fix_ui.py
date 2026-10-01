import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Remove "Not You?" buttons
not_you_student = '''                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearSavedStudent,
                    child: const Text("Not You?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),'''
code = code.replace(not_you_student, '')

not_you_admin = '''                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearSavedAdmin,
                    child: const Text("Not You?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),'''
code = code.replace(not_you_admin, '')

# What if it had if (hasSavedAdmin) before it? (Due to my robust revert previously)
not_you_admin_2 = '''            if (hasSavedAdmin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _clearSavedAdmin,
                  child: const Text("Not You?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),'''
code = code.replace(not_you_admin_2, '')

not_you_student_2 = '''            if (hasSavedStudent)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _clearSavedStudent,
                  child: const Text("Not You?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),'''
code = code.replace(not_you_student_2, '')


# 2. Add SyncService.pushAdmins() to Admin creation
create_admin_old = '''                  if (_newAdminMobileCtrl.text.length == 10 && _newAdminPinCtrl.text.length == 8) {
                    setState(() {
                      globalAdmins.add(AdminUser(_newAdminMobileCtrl.text, hashPassword(_newAdminPinCtrl.text)));
                    });
                    final prefs = await SharedPreferences.getInstance();
                    List<String> adminStrings = globalAdmins.map((a) => jsonEncode(a.toJson())).toList();
                    await prefs.setStringList('globalAdmins', adminStrings);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin created successfully!"), backgroundColor: Colors.green));'''

create_admin_new = '''                  if (_newAdminMobileCtrl.text.length == 10 && _newAdminPinCtrl.text.length == 8) {
                    setState(() {
                      globalAdmins.add(AdminUser(_newAdminMobileCtrl.text, hashPassword(_newAdminPinCtrl.text)));
                    });
                    final prefs = await SharedPreferences.getInstance();
                    List<String> adminStrings = globalAdmins.map((a) => jsonEncode(a.toJson())).toList();
                    await prefs.setStringList('globalAdmins', adminStrings);
                    SyncService.pushAdmins(); // <--- FIXED: PUSH TO FIREBASE
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin created successfully!"), backgroundColor: Colors.green));'''

code = code.replace(create_admin_old, create_admin_new)

# 3. Limit password fields in _handleForgotPassword to strictly 8 chars
forgot_old = '''          content: Column(
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
                }'''

forgot_new = '''          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassCtrl,
                inputFormatters: [LengthLimitingTextInputFormatter(8)],
                decoration: const InputDecoration(hintText: "Enter 8-digit new password"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rePassCtrl,
                inputFormatters: [LengthLimitingTextInputFormatter(8)],
                decoration: const InputDecoration(hintText: "Re-enter password"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (newPassCtrl.text.length != 8) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Password must be exactly 8 characters")));
                  return;
                }'''
code = code.replace(forgot_old, forgot_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("UI and logic fixes applied")
