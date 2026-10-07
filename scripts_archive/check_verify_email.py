import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('Future<void> _verifyEmailAndOtp({required bool isStudentForm}) async {')
if idx != -1:
    print(content[idx:idx+2500])
