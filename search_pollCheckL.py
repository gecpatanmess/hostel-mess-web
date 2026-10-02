import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('_pollCheckL')
while idx != -1:
    print(content[max(0, idx-100):idx+200])
    idx = content.find('_pollCheckL', idx + 10)
