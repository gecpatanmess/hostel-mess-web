with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re
matches = [(m.start(), content[max(0, m.start()-100):m.start()+400]) for m in re.finditer(r'Developed by', content)]
for i, (idx, ctx) in enumerate(matches):
    print(f'--- Instance {i+1} at {idx} ---')
    print(ctx)
