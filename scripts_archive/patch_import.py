import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

pattern = r"(import 'package:flutter/material\.dart';)"
replacement = r"\1\nimport 'package:package_info_plus/package_info_plus.dart';"

if re.search(pattern, code):
    code = re.sub(pattern, replacement, code)
    with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
    print("Added import")
