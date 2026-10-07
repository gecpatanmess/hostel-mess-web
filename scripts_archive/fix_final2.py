with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
skip = False
for line in lines:
    if r'\nvoid main() async {' in line:
        line = line.replace(r'\nvoid main() async {', '\nvoid main() async {')
    if r'AdminUser? _matchedAdmin;\n  RegisteredStudent? _matchedStudent;' in line:
        line = line.replace(r'AdminUser? _matchedAdmin;\n  RegisteredStudent? _matchedStudent;', 'AdminUser? _matchedAdmin;\n  RegisteredStudent? _matchedStudent;')

    # Fix the missing variables by inserting them right after class _LoginScreenState extends State<LoginScreen> {
    if 'class _LoginScreenState extends State<LoginScreen> {' in line:
        new_lines.append(line)
        new_lines.append('  bool _adminEmailVerified = false;\n')
        new_lines.append('  bool isStudentPinVisible = false;\n')
        new_lines.append('  bool isAdminPassVisible = false;\n')
        new_lines.append('  bool hasSavedAdmin = false;\n')
        new_lines.append('  String globalHostelMode = "boys";\n')
        new_lines.append('  bool _isVerifyingEmail = false;\n')
        new_lines.append('  Future<void> _verifyEmailAndOtp({required bool isStudentForm}) async {}\n')
        new_lines.append('  void _handleAdminLogin() {}\n')
        new_lines.append('  void _handleForgotPassword(bool val) {}\n')
        continue

    # We need to completely remove _sendFirebaseAdminOtp and _verifyFirebaseAdminOtp
    # which were added by patch_unified_auth.py.
    # They look like: Future<void> _sendFirebaseAdminOtp() async { ... }
    if 'Future<void> _sendFirebaseAdminOtp() async {' in line:
        skip = True
    if 'Future<void> _verifyFirebaseAdminOtp() async {' in line:
        skip = True

    if skip:
        if '      }' in line and len(line) < 10:  # simplistic check for the end of those specific methods
            skip = False
        continue

    # Also fix some setState issues inside _buildStudentPortal
    if 'selectedRoom = newValue;' in line:
        line = '// selectedRoom = newValue;\n'
    if 'selectedStudentName = null;' in line:
        line = '// selectedStudentName = null;\n'

    new_lines.append(line)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print("Applied clean fixes.")
