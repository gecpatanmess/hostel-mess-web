with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

idx = text.find('class _LoginScreenState')
if idx != -1:
    line = text[:idx].count('\n') + 1
    print("Class starts at line", line)
