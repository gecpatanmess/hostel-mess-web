with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

import re
content = re.sub(r'version: .*', 'version: 1.0.29+29', content)

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated pubspec to 1.0.29")
