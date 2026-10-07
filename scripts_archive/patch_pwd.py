import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

is_valid_func = '''
bool isValidPassword(String password) {
  if (password.length < 8 || password.length > 16) return false;
  if (!password.contains(RegExp(r'[A-Za-z]'))) return false;
  if (!password.contains(RegExp(r'[0-9]'))) return false;
  if (!password.contains(RegExp(r'[!@#%^&*(),.?":{}|<>]'))) return false;
  return true;
}
'''

if "bool isValidPassword" not in text:
    text = text.replace("void main() async {", is_valid_func + "\\nvoid main() async {")

# Admin password creation
text = text.replace(
'''      } else if (_authStage == AuthStage.newPassword) {
           if (typedPin.length != 8 || typedPin != _studentRePinController.text) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords must be 8 chars and match!')));
              return;
           }''',
'''      } else if (_authStage == AuthStage.newPassword) {
           if (!isValidPassword(typedPin)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weak Password! Must be 8-16 chars with letter, number, and symbol.'), backgroundColor: Colors.redAccent));
              return;
           }
           if (typedPin != _studentRePinController.text) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.redAccent));
              return;
           }'''
)

# Student password creation
text = text.replace(
'''    if (_authStage == AuthStage.newPassword) {
        if (typedPin != _studentRePinController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
          return;
        }''',
'''    if (_authStage == AuthStage.newPassword) {
        if (!isValidPassword(typedPin)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weak Password! Must be 8-16 chars with letter, number, and symbol.'), backgroundColor: Colors.redAccent));
          return;
        }
        if (typedPin != _studentRePinController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
          return;
        }'''
)

text = text.replace('maxLength: _authStage == AuthStage.otp ? 6 : (_authStage == AuthStage.standardPassword ? null : 8),', 'maxLength: _authStage == AuthStage.otp ? 6 : (_authStage == AuthStage.standardPassword ? null : 16),')
text = text.replace('maxLength: 8,', 'maxLength: 16,')
text = text.replace('Create 8-char password', 'Create Strong Password')
text = text.replace('Enter 8 digits', 'Enter password')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Added strong password logic back!")
