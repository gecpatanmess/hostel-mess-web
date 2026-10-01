with open('lib/main.dart', 'rb') as f:
    raw_data = f.read()

# Replace any non-utf8 chars or fix it.
code = raw_data.decode('utf-8', errors='replace')

code = code.replace(" 2026 MDHK TENSORS", "(C) 2026 MDHK TENSORS")
code = code.replace("o", "")

import re
pattern = r"(\s*)const Divider\(\),\s*ListTile\(\s*leading: const Icon\(Icons\.logout, color: Colors\.redAccent\),"
def repl(m):
    sp = m.group(1)
    return f"{sp}const Divider(),\n{sp}ListTile(\n{sp}  leading: const Icon(Icons.info_outline, color: brandDark),\n{sp}  title: const Text(\n{sp}    'About Developers',\n{sp}    style: TextStyle(fontWeight: FontWeight.w600),\n{sp}  ),\n{sp}  onTap: () {{\n{sp}    Navigator.pop(context);\n{sp}    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDevelopersScreen()));\n{sp}  }},\n{sp}),\n{sp}const Divider(),\n{sp}ListTile(\n{sp}  leading: const Icon(Icons.logout, color: Colors.redAccent),"

code = re.sub(pattern, repl, code)

# Ensure "Verified" button is clean
code = code.replace('Verified "', 'Verified"')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Fixed encoding and patched drawer")
