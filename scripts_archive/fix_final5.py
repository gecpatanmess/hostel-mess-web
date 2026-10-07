import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

if 'RegisteredStudent? _matchedStudent;' not in text:
    text = text.replace('AdminUser? _matchedAdmin;', 'AdminUser? _matchedAdmin;\n  RegisteredStudent? _matchedStudent;')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Added _matchedStudent!")
