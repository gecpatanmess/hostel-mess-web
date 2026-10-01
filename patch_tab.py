import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

pattern = r"(// Tab Switcher\s+Container\()"
match = re.search(pattern, code)
if match:
    code = code.replace(match.group(1), "if (!hasSavedStudent && !hasSavedAdmin)\n                Container(")
    with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
    print("Tab Switcher hidden for returning users!")
else:
    print("Pattern not found!")
