import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Remove all existing About Developers blocks
# We know the block starts with const Divider() and ends before the LogOut divider.
# Specifically, we want to remove:
# \s*const Divider\(\),\s*ListTile\(\s*leading: const Icon\(Icons\.info_outline, color: brandDark\),.*?Navigator\.push\(context, MaterialPageRoute\(builder: \(context\) => const AboutDevelopersScreen\(\)\)\);\s*},\s*\),
import re
pattern_remove = r"(\s*)const Divider\(\),\s*ListTile\(\s*leading: const Icon\(Icons\.info_outline, color: brandDark\),.*?AboutDevelopersScreen\(\)\)\);\s*},\s*\),"
code = re.sub(pattern_remove, "", code, flags=re.DOTALL)

# Now apply exactly ONCE to every LogOut
pattern_insert = r"(\s*)const Divider\(\),\s*ListTile\(\s*leading: const Icon\(Icons\.logout, color: Colors\.redAccent\),"

def repl(m):
    sp = m.group(1)
    return f"{sp}const Divider(),\n{sp}ListTile(\n{sp}  leading: const Icon(Icons.info_outline, color: brandDark),\n{sp}  title: const Text(\n{sp}    'About Developers',\n{sp}    style: TextStyle(fontWeight: FontWeight.w600),\n{sp}  ),\n{sp}  onTap: () {{\n{sp}    Navigator.pop(context);\n{sp}    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDevelopersScreen()));\n{sp}  }},\n{sp}),\n{sp}const Divider(),\n{sp}ListTile(\n{sp}  leading: const Icon(Icons.logout, color: Colors.redAccent),"

code = re.sub(pattern_insert, repl, code)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Cleaned up and applied About Developers exactly once to all drawers")
