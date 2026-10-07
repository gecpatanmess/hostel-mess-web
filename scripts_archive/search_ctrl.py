with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if '_newAdminMobileCtrl' in line:
        print(f'{i}: {line.strip()}')
