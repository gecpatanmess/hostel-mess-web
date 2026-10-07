with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

idx = text.find('Widget _buildPasswordField')
if idx != -1:
    line = text[:idx].count('\n') + 1
    print("_buildPasswordField at line", line)
