import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace EVERYTHING between _sendFirebaseAdminOtp and _finalizeAdminLogin
pattern = r'Future<void> _sendFirebaseAdminOtp\(\) async \{[\s\S]*?Future<void> _finalizeAdminLogin'
replacement = '''Future<void> _sendFirebaseAdminOtp() async {}
    Future<void> _verifyFirebaseAdminOtp(String otp) async {}
  Future<void> _finalizeAdminLogin'''

text = re.sub(pattern, replacement, text)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Deleted Firebase OTP bodies entirely!")
