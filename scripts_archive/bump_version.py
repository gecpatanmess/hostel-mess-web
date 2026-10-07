import re
import sys

def replace_version(file_path, old, new):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(old, new)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

replace_version('pubspec.yaml', 'version: 1.0.42+42', 'version: 1.0.44+44')
replace_version('package.json', '"version": "1.0.42"', '"version": "1.0.44"')
replace_version('lib/main.dart', 'v1.0.42', 'v1.0.44')
print('Version bumped to 1.0.44')
