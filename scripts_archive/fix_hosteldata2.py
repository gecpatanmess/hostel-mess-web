import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("'hostelData_'", "'hostelData_$globalHostelMode'")
text = text.replace("'hostelData_/", "'hostelData_$globalHostelMode/")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Fixed broken string replacements")
