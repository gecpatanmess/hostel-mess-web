import sys

with open('lib/update_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

if "import 'main.dart';" not in text:
    text = text.replace("import 'package:supabase_flutter/supabase_flutter.dart';", "import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'main.dart';")

with open('lib/update_service.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Added main.dart import")
