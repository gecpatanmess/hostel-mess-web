import re
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

matches = [(m.start(), content[max(0, m.start()-500):m.start()+1000]) for m in re.finditer(r'CircleAvatar', content, re.IGNORECASE)]
for i, (idx, ctx) in enumerate(matches):
    if 'GestureDetector' in ctx or 'InkWell' in ctx or 'pickImage' in ctx:
        print(f'--- {i} ---')
        print(ctx[:800])
