import re

with open('patch_unified_auth.py', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace the methods with stubs inside the patch script
pattern1 = r'Future<void> _sendFirebaseAdminOtp\(\) async \{[\s\S]*?\}\n    \}\n  '
text = re.sub(pattern1, 'Future<void> _sendFirebaseAdminOtp() async {}\n  ', text)

pattern2 = r'Future<void> _verifyFirebaseAdminOtp\(String otp\) async \{[\s\S]*?\}\n    \}\n  '
text = re.sub(pattern2, 'Future<void> _verifyFirebaseAdminOtp(String otp) async {}\n  ', text)

with open('patch_unified_auth.py', 'w', encoding='utf-8') as f:
    f.write(text)
print("Modified patch_unified_auth.py to not inject Firebase OTP!")
