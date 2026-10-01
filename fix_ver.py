with open('lib/main.dart', 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace('Version 1.0.28', 'Version 1.0.29')
with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(c)
