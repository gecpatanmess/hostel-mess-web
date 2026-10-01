with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
idx = content.find('Photo/PDF Menu')
if idx != -1:
    print(content[max(0,idx-500):idx+2000])
