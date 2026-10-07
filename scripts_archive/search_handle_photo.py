import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('studentPhotoUrl == null')
while idx != -1:
    ctx = content[max(0, idx-100):idx+400]
    if 'existingStudent' in ctx:
        print('---')
        print(ctx)
    idx = content.find('studentPhotoUrl == null', idx + 10)
