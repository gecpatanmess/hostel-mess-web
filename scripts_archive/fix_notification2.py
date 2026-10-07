import sys

with open('lib/notification_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = "import 'main.dart';\n" + text

with open('lib/notification_service.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Added import to notification_service.dart")
