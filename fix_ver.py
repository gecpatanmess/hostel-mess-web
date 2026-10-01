with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

import re
content = re.sub(r'version: .*', 'version: 1.0.30+30', content)

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(content)

with open('lib/update_service.dart', 'r', encoding='utf-8') as f:
    uc = f.read()

uc = uc.replace('1.0.29', '1.0.30')

with open('lib/update_service.dart', 'w', encoding='utf-8') as f:
    f.write(uc)
    
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    mc = f.read()
mc = mc.replace('Version 1.0.29', 'Version 1.0.30')
with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(mc)

print("Updated versions to 1.0.30")
