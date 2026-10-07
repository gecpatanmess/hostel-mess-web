with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('version: 1.0.28+28', 'version: 1.0.29+29')

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(content)

with open('lib/update_service.dart', 'r', encoding='utf-8') as f:
    update_content = f.read()

update_content = update_content.replace('1.0.28', '1.0.29')

with open('lib/update_service.dart', 'w', encoding='utf-8') as f:
    f.write(update_content)

print("Updated version to 1.0.29")
