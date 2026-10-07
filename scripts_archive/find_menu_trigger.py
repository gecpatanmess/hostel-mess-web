with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
idx = content.find('final defaultMenu = defaultWeeklyMenu[weekDay]')
if idx != -1:
    print(content[max(0,idx-200):idx+50])
