import sys

with open('lib/notification_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("'hostelData/", "'hostelData_${globalHostelMode}/")

with open('lib/notification_service.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Fixed notification_service.dart")
