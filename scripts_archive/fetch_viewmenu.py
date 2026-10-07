with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
idx = content.find('class ViewMenuTab')
if idx != -1:
    print(content[idx:idx+4000])
