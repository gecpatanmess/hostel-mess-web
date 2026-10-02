with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Strip whitespace and check if last char is }
code = code.strip()
if code.endswith('}'):
    # find the second to last }
    idx = code.rfind('}', 0, len(code) - 1)
    if idx != -1:
        print("Found extra brace at the end")
        # We know we have an extra } at the very end. Let's just remove the last one!
        code = code[:-1].strip()

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code + '\n')
print('Removed extra brace!')
