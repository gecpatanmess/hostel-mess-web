import re
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

matches = [(m.start(), content[m.start():m.start()+2500]) for m in re.finditer(r'(?:void|Future<void>)?\s*\w*Forgot\w*\(', content)]
for i, (idx, ctx) in enumerate(matches):
    if 'bool ' in ctx or 'isStudent' in ctx or 'isAppAdmin' in ctx or 'true' in ctx:
        print(f'--- {i} ---')
        print(ctx[:800])
