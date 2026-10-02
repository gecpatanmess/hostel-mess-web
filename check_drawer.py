with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
idx = content.find('Edit Weekly Timetable')
if idx != -1:
    print('FOUND at index', idx)
    print(content[max(0,idx-300):idx+300])
else:
    print('NOT FOUND!')
    # Check for Set Menu
    idx2 = content.find('Set Menu')
    if idx2 != -1:
        print('Set Menu found at:', idx2)
        print(content[max(0,idx2-100):idx2+500])
