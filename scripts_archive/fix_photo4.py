import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('final File photo;', 'final String? photoUrl;')
content = content.replace('final File? photo;', 'final String? photoUrl;')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Forcibly replaced!")
