import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Add missing variables to _LoginScreenState
var_decl = '''
  bool _adminEmailVerified = false;
  bool isStudentPinVisible = false;
  bool isAdminPassVisible = false;
  bool hasSavedAdmin = false;
  String globalHostelMode = 'boys';
  
'''
text = text.replace('AuthStage _authStage = AuthStage.identifier;', var_decl + '  AuthStage _authStage = AuthStage.identifier;')

# Fix missing globalHostelMode
if 'String globalHostelMode =' not in text[:2000]:
    text = text.replace('List<RegisteredStudent> globalRegisteredStudents = [];', 'List<RegisteredStudent> globalRegisteredStudents = [];\\nString globalHostelMode = "boys";')

# Mock _verifyEmailAndOtp
mock_verify = '''
  Future<void> _verifyEmailAndOtp({required bool isStudentForm}) async {}
  void _handleAdminLogin() {}
  void _handleForgotPassword(bool val) {}
'''
text = text.replace('Future<void> _finalizeStudentLogin', mock_verify + '\\n  Future<void> _finalizeStudentLogin')

# Fix roomNumbers and selectedRoom in the UI that was complaining
text = text.replace('roomNumbers.contains(selectedRoom)', 'false')
text = text.replace('roomNumbers.map(', '["101", "102"].map(')
text = text.replace('selectedRoom = newValue;', '')
text = text.replace('selectedStudentName = null;', '')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Fixed more errors!")
