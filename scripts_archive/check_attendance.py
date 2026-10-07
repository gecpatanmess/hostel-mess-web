import re
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('void _submitAttendance')
if idx != -1:
    print(content[idx:idx+1500])
else:
    print('Not found _submitAttendance')
