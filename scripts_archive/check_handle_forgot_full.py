with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('Future<void> _handleForgotPassword(bool isStudentReq) async {')
if idx != -1:
    print(content[idx:idx+2500])
