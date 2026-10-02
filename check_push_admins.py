with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
import re
matches = [(m.start(), content[m.start():m.start()+400]) for m in re.finditer(r'static.*pushAdmins', content)]
print(f'Found {len(matches)} pushAdmins definitions')
for i, (idx, ctx) in enumerate(matches):
    print(f'--- {i+1} at {idx} ---')
    print(ctx)
