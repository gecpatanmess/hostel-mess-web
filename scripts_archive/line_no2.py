with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

idx = text.find('bool isStudentPinVisible')
if idx != -1:
    line = text[:idx].count('\n') + 1
    print("Found at line", line)
else:
    print("Not found!")
