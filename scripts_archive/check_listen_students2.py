import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('globalRegisteredStudents.clear();')
while idx != -1:
    if \"data['students']\" in content[idx:idx+200]:
        print('-----------')
        print(content[idx:idx+800])
    idx = content.find('globalRegisteredStudents.clear();', idx + 10)
