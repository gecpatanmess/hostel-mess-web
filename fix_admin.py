import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Inject pushAdmins() when creating a new Admin
admin_search = r"(globalAdmins\.map\(\(a\) => jsonEncode\(\a\.toJson\(\)\)\)\.toList\(\);\s+await prefs\.setStringList\('globalAdmins', adminStrings\);)"
admin_replace = r"\1\n                  SyncService.pushAdmins();"

code = re.sub(admin_search, admin_replace, code)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("pushAdmins injected")
