with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old = """                  await prefs.setStringList('globalAdmins', adminStrings);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin created successfully!"), backgroundColor: Colors.green));"""

new = """                  await prefs.setStringList('globalAdmins', adminStrings);
                  SyncService.pushAdmins();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin created successfully!"), backgroundColor: Colors.green));"""

code = code.replace(old, new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("pushAdmins() injected!")
