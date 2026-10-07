import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

drawer_replacement = """              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline, color: brandDark),
                title: const Text(
                  'About Developers',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDevelopersScreen()));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),"""

# Using regex to replace
code = re.sub(
    r"              const Divider\(\),\s*ListTile\(\s*leading: const Icon\(Icons\.logout, color: Colors\.redAccent\),",
    drawer_replacement,
    code
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Drawers updated via regex")
