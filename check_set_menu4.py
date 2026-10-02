import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('void _showSetMenuDialog()')
if idx != -1:
    print(content[idx+4500:idx+6000])
