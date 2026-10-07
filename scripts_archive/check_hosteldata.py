import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'hostelData' in line:
        if 'hostelData_$globalHostelMode' not in line and 'hostelData_$mode' not in line:
            print(f"Line {i+1}: {line.strip()}")
