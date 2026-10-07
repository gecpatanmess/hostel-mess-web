import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace(r'\n', '\n')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Fixed backslash n!")
