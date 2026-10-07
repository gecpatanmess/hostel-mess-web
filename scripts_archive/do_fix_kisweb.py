import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final isWeb = kIsWeb;", "final isWeb = true;")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed kIsWeb")
