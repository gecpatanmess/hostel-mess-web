import re
with open('lib/main.dart.bak', 'r', encoding='utf-8') as f: code = f.read()
if "data['students']" in code: print("Found students in old code")
else: print("NOT FOUND in old code")
