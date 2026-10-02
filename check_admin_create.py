with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
import re
# Find all places where admins are created/added
matches = [(m.start(), content[max(0,m.start()-100):m.start()+300]) for m in re.finditer(r'globalAdmins\.add', content)]
print(f'Found {len(matches)} instances of globalAdmins.add')
for i, (idx, ctx) in enumerate(matches):
    print(f'--- Instance {i+1} at {idx} ---')
    print(ctx)
    print()
