with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('void _handleForgotPassword(bool isStudent)')
if idx != -1:
    print(content[idx:idx+2500])
