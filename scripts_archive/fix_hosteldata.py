import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace hardcoded 'hostelData/...' with 'hostelData_/...'
text = re.sub(
    r"'hostelData(/|')",
    r"'hostelData_\1",
    text
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Replaced hardcoded hostelData")
