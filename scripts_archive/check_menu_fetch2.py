with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re
matches = [(m.start(), content[m.start():m.start()+2000]) for m in re.finditer(r'class ViewMenuTab', content)]
for i, (idx, ctx) in enumerate(matches):
    print(f'--- {i+1} ---')
    print(ctx)
