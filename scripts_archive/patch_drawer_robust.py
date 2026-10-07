import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

replacement = """            const Divider(),
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

# Let's replace any instance of:
# (any spaces)const Divider(),\n(any spaces)ListTile(\n(any spaces)leading: const Icon(Icons.logout, color: Colors.redAccent),
pattern = r"(\s*)const Divider\(\),\s*ListTile\(\s*leading: const Icon\(Icons\.logout, color: Colors\.redAccent\),"
def repl(m):
    sp = m.group(1)
    return f"{sp}const Divider(),\n{sp}ListTile(\n{sp}  leading: const Icon(Icons.info_outline, color: brandDark),\n{sp}  title: const Text(\n{sp}    'About Developers',\n{sp}    style: TextStyle(fontWeight: FontWeight.w600),\n{sp}  ),\n{sp}  onTap: () {{\n{sp}    Navigator.pop(context);\n{sp}    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDevelopersScreen()));\n{sp}  }},\n{sp}),\n{sp}const Divider(),\n{sp}ListTile(\n{sp}  leading: const Icon(Icons.logout, color: Colors.redAccent),"

code = re.sub(pattern, repl, code)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Drawers updated via robust regex")
