with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
# The weekly edit drawer item should be near 'Set Menu'
idx = content.find('Set Menu')
if idx != -1:
    print(content[max(0,idx-100):idx+800])
