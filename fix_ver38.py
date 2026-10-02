with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()
import re
content = re.sub(r'version: .*', 'version: 1.0.38+38', content)
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(content)

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    mc = f.read()
mc = mc.replace('Version 1.0.37', 'Version 1.0.38')
with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(mc)
print('Updated to 1.0.38')
