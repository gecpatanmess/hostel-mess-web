import re
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

matches = [(m.start(), content[max(0, m.start()-200):m.start()+800]) for m in re.finditer(r'attendance', content, re.IGNORECASE)]
for i, (idx, ctx) in enumerate(matches):
    print(f'--- {i} ---')
    print(ctx)
