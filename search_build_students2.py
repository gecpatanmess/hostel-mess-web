import re
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('AdminDashboardScreen')
if idx != -1:
    matches = [(m.start(), content[max(0, m.start()-500):m.start()+1000]) for m in re.finditer(r'ListView\.builder', content[idx:idx+20000])]
    for i, (midx, ctx) in enumerate(matches):
        if 'student' in ctx.lower() or 'room' in ctx.lower():
            print(f'--- {i} ---')
            print(ctx[:1000])
