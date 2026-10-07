import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

pattern = r"Future<void> _loadDataFromPrefs\(\) async \{\s*final prefs = await SharedPreferences\.getInstance\(\);"
replacement = """Future<void> _loadDataFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final savedVersion = prefs.getString('installed_version');
    if (savedVersion != currentVersion) {
      await prefs.setString('installed_version', currentVersion);
      if (savedVersion != null) {
        await prefs.remove('userType');
      }
    }
  } catch(e) {}"""

if re.search(pattern, code):
    code = re.sub(pattern, replacement, code)
    with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
    print("Patched version check")
else:
    print("Not found")
