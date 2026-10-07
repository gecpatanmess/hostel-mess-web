import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add Dio import
if "import 'package:dio/dio.dart';" not in code:
    code = code.replace("import 'package:file_picker/file_picker.dart';", "import 'package:file_picker/file_picker.dart';\nimport 'package:dio/dio.dart';")

# 2. Add Login State variables
state_vars = '''  bool isStudent = true;
  bool isStudentPinVisible = false;
  bool isAdminPassVisible = false;
  bool _studentEmailVerified = false;
  bool _adminEmailVerified = false;
  bool _isVerifyingEmail = false;
  String? selectedStudentName;

  final _studentFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  final TextEditingController _studentEmailController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();'''
  
code = re.sub(r'  bool isStudent = true;.*?final _adminFormKey = GlobalKey<FormState>\(\);', state_vars, code, flags=re.DOTALL)

# 3. Add _verifyEmail helper function before _handleStudentLogin
verify_helper = '''
  Future<void> _verifyEmail(String email, bool isStudentForm) async {
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isVerifyingEmail = true);

    // Step 1: Deep email validation via backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking email...'), duration: Duration(seconds: 2)),
    );

    final validationResult = await EmailOtpService.verifyEmail(email);

    if (validationResult['valid'] != true) {
      setState(() => _isVerifyingEmail = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid email: \'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isVerifyingEmail = false);

    // Step 2: Send OTP and show verification dialog
    if (!mounted) return;
    final verified = await showOtpVerificationDialog(context, email);

    if (verified) {
      setState(() {
        if (isStudentForm) {
          _studentEmailVerified = true;
        } else {
          _adminEmailVerified = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('? Email verified successfully!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _handleStudentLogin() async {'''

code = code.replace("  void _handleStudentLogin() async {", verify_helper)

# 4. Add Student Email Field before the Password Field
student_field = '''            TextFormField(
              controller: _studentEmailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Required for first time login',
                prefixIcon: const Icon(Icons.email),
                suffixIcon: _studentEmailVerified 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : TextButton(
                      onPressed: _isVerifyingEmail ? null : () => _verifyEmail(_studentEmailController.text.trim(), true),
                      child: _isVerifyingEmail ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Verify"),
                    ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (!hasSavedStudent && (val == null || val.isEmpty)) return "Required for registration";
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildPasswordField('''

code = code.replace("            _buildPasswordField(\n              controller: _studentPinController,", student_field + "\n              controller: _studentPinController,")

# 5. Add Admin Email Field before Password Field
admin_field = '''            TextFormField(
              controller: _adminEmailController,
              decoration: InputDecoration(
                labelText: 'Admin Email',
                hintText: 'Required for first time login',
                prefixIcon: const Icon(Icons.email),
                suffixIcon: _adminEmailVerified 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : TextButton(
                      onPressed: _isVerifyingEmail ? null : () => _verifyEmail(_adminEmailController.text.trim(), false),
                      child: _isVerifyingEmail ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Verify"),
                    ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (!hasSavedAdmin && (val == null || val.isEmpty)) return "Required for registration";
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildPasswordField('''

code = code.replace("            _buildPasswordField(\n              controller: _adminPasswordController,", admin_field + "\n              controller: _adminPasswordController,")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Manual patches applied!")
