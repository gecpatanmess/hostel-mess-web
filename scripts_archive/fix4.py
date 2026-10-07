import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Restore the commented out stuff so we can just delete the whole function
text = text.replace('// FirebaseAuth.instance', 'FirebaseAuth.instance')
text = text.replace('// PhoneAuthProvider.credential', 'PhoneAuthProvider.credential')
text = text.replace('// PhoneAuthCredential credential', 'PhoneAuthCredential credential')

# Delete _sendFirebaseAdminOtp entirely
text = re.sub(r'Future<void> _sendFirebaseAdminOtp\(\) async \{.*?\n      \}', 
    'Future<void> _sendFirebaseAdminOtp() async {}', text, flags=re.DOTALL)

# Delete _verifyFirebaseAdminOtp entirely
text = re.sub(r'Future<void> _verifyFirebaseAdminOtp\(\) async \{.*?\n       \}', 
    'Future<void> _verifyFirebaseAdminOtp() async {}', text, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Removed Firebase OTP methods!")
