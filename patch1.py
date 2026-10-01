import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

pattern = r"if \(!hasSavedAdmin && _adminEmailController\.text\.isNotEmpty\) \{\s*admin\.email = _adminEmailController\.text\.trim\(\);\s*\}"
replacement = """if (!hasSavedAdmin && _adminEmailController.text.isNotEmpty) {
              admin.email = _adminEmailController.text.trim();
              SyncService.pushAdmins();
            }"""

if re.search(pattern, code):
    code = re.sub(pattern, replacement, code)
    with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
    print("Patched!")
else:
    print("Not found!")
