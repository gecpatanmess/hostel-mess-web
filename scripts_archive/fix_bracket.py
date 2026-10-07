with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Let's see the last 100 characters of the file
print('LAST 100 CHARS:', repr(code[-100:]))
