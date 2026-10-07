import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("Text('Error: \\')", "Text('Error: ')")
text = text.replace("Text(\"Error: \\\")", "Text('Error: ')")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Direct string replacement applied.")
