import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace try-catch inside _sendFirebaseAdminOtp
pattern1 = r'try \{\s*await // FirebaseAuth\.instance\.verifyPhoneNumber\([\s\S]*?\} catch \(e\) \{\s*setState\(\(\) => _isVerifyingEmail = false\);\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\(.*?\}\s*'
text = re.sub(pattern1, 'setState(() => _isVerifyingEmail = false);', text)

# Replace try-catch inside _verifyFirebaseAdminOtp
pattern2 = r'try \{\s*PhoneAuthCredential credential = // PhoneAuthProvider\.credential\([\s\S]*?\} catch\(e\) \{\s*setState\(\(\) => _isVerifyingEmail = false\);\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\(.*?\}\s*'
text = re.sub(pattern2, 'setState(() => _isVerifyingEmail = false);', text)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Removed Firebase try-catch blocks!")
