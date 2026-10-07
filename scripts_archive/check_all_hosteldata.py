import os

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                for i, line in enumerate(f):
                    if 'hostelData' in line and 'hostelData_$globalHostelMode' not in line and 'hostelData_$mode' not in line:
                        print(f"{file} Line {i+1}: {line.strip()}")
