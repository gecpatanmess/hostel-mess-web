import re
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

matches = [(m.start(), content[max(0, m.start()-500):m.start()+1000]) for m in re.finditer(r'DropdownButtonFormField', content)]
for i, (idx, ctx) in enumerate(matches):
    if 'selectedStudentName' in ctx:
        print(f'--- {i} ---')
        print(ctx[500:])
