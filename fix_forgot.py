with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old = """admin.pin = newPassCtrl.text;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('globalAdmins', globalAdmins.map((a) => jsonEncode(a.toJson())).toList());
            SyncService.pushAdmins();"""

new = """admin.pin = hashPassword(newPassCtrl.text);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('globalAdmins', globalAdmins.map((a) => jsonEncode(a.toJson())).toList());
            SyncService.pushAdmins();"""

code = code.replace(old, new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Fixed forgot password hash")
