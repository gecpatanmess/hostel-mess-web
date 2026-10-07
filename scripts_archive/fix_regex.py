import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r"Text\('Error: \\\'\)", "Text('Error: ')", text)
text = re.sub(r'Text\("Error: \\\"\)', 'Text("Error: ")', text)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Regex applied.")
