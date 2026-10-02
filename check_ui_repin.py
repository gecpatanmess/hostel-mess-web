import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('_studentRePinController')
while idx != -1:
    print('======================')
    print(content[max(0, idx-500):idx+1000])
    idx = content.find('_studentRePinController', idx + 10)
