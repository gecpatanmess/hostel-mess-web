import sys

with open('lib/update_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace common 'app_updates' with dynamic mode
text = text.replace("'app_updates'", "'app_updates_'")

with open('lib/update_service.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Changed to dynamic app_updates")
