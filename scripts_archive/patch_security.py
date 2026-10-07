import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

changes = 0

# 1. Hash the default admin password
old1 = 'List<AdminUser> globalAdmins = [AdminUser("9586401483", "dax123")];'
new1 = 'List<AdminUser> globalAdmins = [AdminUser("9586401483", "c984aed014aec7623a54f0591da07a85fd4b762d68a75e0ac3f3d7a45b6a1e4c")];'
if old1 in code:
    code = code.replace(old1, new1)
    changes += 1

# 2. Hash the master reset password comparison
old2 = 'if (passCtrl.text == "asdfg lkjh zxcvb mn")'
new2 = 'if (hashPassword(passCtrl.text) == "e04e0e7bcc1345003115e9e02cdd5b8e16b0db8c8d4a76e6ab48ee52cbda8954")'
if old2 in code:
    code = code.replace(old2, new2)
    changes += 1

# 3. Admin login: compare with both hashed and plain (migration support)
old3 = '''if (admin.pin == pin) {'''
new3 = '''if (admin.pin == hashPassword(pin) || admin.pin == pin) {'''
if old3 in code:
    code = code.replace(old3, new3)
    changes += 1

# 4. New admin creation: hash password before storing
old4 = 'globalAdmins.add(AdminUser(_newAdminMobileCtrl.text, _newAdminPinCtrl.text));'
new4 = 'globalAdmins.add(AdminUser(_newAdminMobileCtrl.text, hashPassword(_newAdminPinCtrl.text)));'
code = code.replace(old4, new4)
changes += 1

# 5. Admin password change: hash the new password
old5 = 'currentAdmin.pin = _changeAdminPinCtrl.text;'
new5 = 'currentAdmin.pin = hashPassword(_changeAdminPinCtrl.text);'
if old5 in code:
    code = code.replace(old5, new5)
    changes += 1

# 6. Forgot password reset for admin: hash the new password
old6 = '''admin.pin = newPassCtrl.text;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('globalAdmins', globalAdmins.map((a) => jsonEncode(a.toJson())).toList());
            SyncService.pushAdmins();'''
new6 = '''admin.pin = hashPassword(newPassCtrl.text);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('globalAdmins', globalAdmins.map((a) => jsonEncode(a.toJson())).toList());
            SyncService.pushAdmins();'''
if old6 in code:
    code = code.replace(old6, new6)
    changes += 1

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print(f"Applied {changes} security patches")
