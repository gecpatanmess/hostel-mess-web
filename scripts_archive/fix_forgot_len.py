import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix the forgot password dialog password length constraint
code = code.replace(
    '''TextField(controller: newPassCtrl, decoration: const InputDecoration(hintText: "Enter 8-digit new password")),''',
    '''TextField(controller: newPassCtrl, inputFormatters: [LengthLimitingTextInputFormatter(8)], decoration: const InputDecoration(hintText: "Enter 8-digit new password")),'''
)

code = code.replace(
    '''TextField(controller: rePassCtrl, decoration: const InputDecoration(hintText: "Re-enter password")),''',
    '''TextField(controller: rePassCtrl, inputFormatters: [LengthLimitingTextInputFormatter(8)], decoration: const InputDecoration(hintText: "Re-enter password")),'''
)

code = code.replace(
    '''if (newPassCtrl.text.length < 8) {''',
    '''if (newPassCtrl.text.length != 8) {'''
)

code = code.replace(
    '''if (typedPin.length < 8) {''',
    '''if (typedPin.length != 8) {'''
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Forgot pass length limits applied")
