import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace hardcoded paths in the UI with dynamic globalHostelMode logic
text = text.replace(
    "FirebaseDatabase.instance.ref('hostelData/weekly_template/').get()",
    "FirebaseDatabase.instance.ref('hostelData_/weekly_template/').get()"
)

text = text.replace(
    "FirebaseDatabase.instance.ref('hostelData/daily_menus/').get()",
    "FirebaseDatabase.instance.ref('hostelData_/daily_menus/').get()"
)

text = text.replace(
    "FirebaseDatabase.instance.ref('hostelData/daily_menus/').set",
    "FirebaseDatabase.instance.ref('hostelData_/daily_menus/').set"
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Fixed hardcoded daily_menus and weekly_template")
