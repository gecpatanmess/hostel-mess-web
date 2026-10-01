import re
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
matches = [m.start() for m in re.finditer(r'_showSetMenuDialog', content)]
for idx in matches:
    print('---')
    print(content[max(0,idx-200):idx+200])
