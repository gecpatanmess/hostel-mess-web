import sys

with open('lib/update_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("'app_updates_'", "'app_updates_$globalHostelMode'")

with open('lib/update_service.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Escaped properly")
