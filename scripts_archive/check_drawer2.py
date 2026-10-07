with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
# Check if the drawer ListTile for weekly edit was injected
idx = content.find('Edit Weekly Timetable')
# Find ALL instances
import re
matches = [(m.start(), m.group()) for m in re.finditer(r'Edit Weekly Timetable', content)]
print(f'Found {len(matches)} instances')
for m in matches:
    print(f'  at index {m[0]}')

# Check the drawer specifically
idx2 = content.find('calendar_month')
if idx2 != -1:
    print('calendar_month FOUND at:', idx2)
    print(content[max(0,idx2-200):idx2+300])
else:
    print('calendar_month NOT FOUND in drawer!')
    # Check Set Menu (Today) 
    idx3 = content.find('Set Menu (Today)')
    if idx3 != -1:
        print('Set Menu (Today) found')
    else:
        print('Set Menu (Today) NOT FOUND either')
        idx4 = content.find('Set Menu')
        if idx4 != -1:
            print('Original Set Menu found at:', idx4)
            print(content[max(0,idx4-100):idx4+600])
