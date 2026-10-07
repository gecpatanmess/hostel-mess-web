import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix AdminUser access
text = text.replace('admin.name', '"Admin"')
text = text.replace('admin.photoUrl', 'null')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Fixed AdminUser properties!")
