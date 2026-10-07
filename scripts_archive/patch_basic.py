import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add crypto import and navigator key
if "import 'package:crypto/crypto.dart';" not in code:
    code = code.replace("import 'package:shared_preferences/shared_preferences.dart';", "import 'package:shared_preferences/shared_preferences.dart';\nimport 'package:crypto/crypto.dart';")

if "final GlobalKey<NavigatorState> globalNavigatorKey =" not in code:
    code = code.replace("bool globalEntryL = false;", "final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();\nint globalAppStartTime = DateTime.now().millisecondsSinceEpoch;\n\nvoid handleForceLogout() async {\n  final prefs = await SharedPreferences.getInstance();\n  await prefs.clear();\n  if (globalNavigatorKey.currentContext != null) {\n    Navigator.pushAndRemoveUntil(\n      globalNavigatorKey.currentContext!,\n      MaterialPageRoute(builder: (context) => const LoginScreen()),\n      (route) => false,\n    );\n  }\n}\n\nbool globalEntryL = false;")

code = code.replace("return MaterialApp(", "return MaterialApp(\n        navigatorKey: globalNavigatorKey,")

# 2. Add hashing helper
if "String hashPassword(String password)" not in code:
    code = code.replace("class SyncService {", "String hashPassword(String password) {\n  var bytes = utf8.encode(password);\n  var digest = sha256.convert(bytes);\n  return digest.toString();\n}\n\nclass SyncService {")

# 3. Add force logout to performReset
reset_target = """      SyncService.pushStudents();
      globalSyncTrigger.value++;"""
reset_replacement = """      SyncService.pushStudents();
      await dbRef.child('force_logout').set(DateTime.now().millisecondsSinceEpoch);
      globalSyncTrigger.value++;"""
code = code.replace(reset_target, reset_replacement)

# 4. Listen to force_logout
listen_target = """          if (data['switches'] != null && !_switchCooldown) {"""
listen_replacement = """          if (data['force_logout'] != null) {
            int logoutTime = data['force_logout'];
            if (logoutTime > globalAppStartTime) {
              globalAppStartTime = DateTime.now().millisecondsSinceEpoch; // prevent loop
              handleForceLogout();
            }
          }
          if (data['switches'] != null && !_switchCooldown) {"""
code = code.replace(listen_target, listen_replacement)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Patched basic setup")
