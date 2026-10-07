import sys
import io

def rep(file, old, new):
    with open(file, 'r', encoding='utf-8') as f:
        c = f.read()
    with open(file, 'w', encoding='utf-8') as f:
        f.write(c.replace(old, new))

rep('pubspec.yaml', 'version: 1.0.42+42', 'version: 1.0.44+44')
rep('lib/main.dart', 'v1.0.42', 'v1.0.44')
rep('../hostel-backend/package.json', '"version": "1.0.42"', '"version": "1.0.44"')
print('done')
