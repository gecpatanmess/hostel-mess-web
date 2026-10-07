import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the logout block with the info block + logout block
drawer_button = """
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
              title: const Text('About Developers', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDevelopersScreen()));
              },
            ),
            const Divider(),
"""

content = re.sub(
    r'(const Divider\(\),\s*ListTile\(\s*leading:\s*const\s*Icon\(Icons\.logout,\s*color:\s*Colors\.redAccent\),\s*title:\s*const\s*Text\(\'LogOut\')',
    drawer_button + r'\1',
    content
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Injected into drawers")
