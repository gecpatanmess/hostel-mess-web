import re

with open('patch_unified_auth.py', 'r', encoding='utf-8') as f:
    text = f.read()

# Make it insert AuthStage directly
text = text.replace(
'''if "enum AuthStage" not in text:
    text = text.replace("enum StudentLoginStage { email, enterPassword, setPassword }", 
                        "enum AuthStage { identifier, standardPassword, newPassword, personalPassword, otp }")
    text = text.replace("StudentLoginStage _studentStage = StudentLoginStage.email;", 
                        "AuthStage _authStage = AuthStage.identifier;\\n  bool _isAdminFlow = false;\\n  AdminUser? _matchedAdmin;\\n  String _adminVerificationId = '';")''',
'''if "enum AuthStage" not in text:
    text = text.replace("class _LoginScreenState extends State<LoginScreen> {",
                        "enum AuthStage { identifier, standardPassword, newPassword, personalPassword, otp }\\n\\nclass _LoginScreenState extends State<LoginScreen> {")
    text = text.replace("bool isStudent = true;",
                        "AuthStage _authStage = AuthStage.identifier;\\n  bool _isAdminFlow = false;\\n  AdminUser? _matchedAdmin;\\n  String _adminVerificationId = '';\\n\\n  bool isStudent = true;")'''
)

with open('patch_unified_auth.py', 'w', encoding='utf-8') as f:
    f.write(text)
print("Fixed patch_unified_auth.py")
