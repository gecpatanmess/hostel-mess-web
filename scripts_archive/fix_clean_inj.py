with open('do_clean_injection.py', 'r', encoding='utf-8') as f:
    code = f.read()
code = code.replace("open('lib/main.dart.bak'", "open('lib/main.dart'")
with open('do_clean_injection.py', 'w', encoding='utf-8') as f:
    f.write(code)
print('Fixed do_clean_injection.py')
