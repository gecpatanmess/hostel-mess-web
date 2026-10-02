with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('Widget _buildAdminsTab()')
if idx != -1:
    print(content[idx:idx+2500])
