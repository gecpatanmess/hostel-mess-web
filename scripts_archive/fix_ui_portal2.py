import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Student Portal
# Match from '_buildPasswordField' for _studentPinController
# We want to place ], if (!hasSavedStudent) ...[ around it.
student_re = r'(\s+const SizedBox\(height: 20\),\s+_buildPasswordField\(\s+controller: _studentPinController,)'
student_replacement = r'\n              ],\n              if (hasSavedStudent) ...[\n                const SizedBox(height: 20),\n              ],\n\1'

# Wait, if we just close the array and reopen it, we have to be careful.
# Original structure:
# if (!hasSavedStudent) ...[
#    ...
#    const SizedBox(height: 20),
#    _buildPasswordField(controller: _studentPinController ...)
#    const SizedBox(height: 20),
#    _buildPasswordField(controller: _studentRePinController ...)
#    ...
# ]
# So we need to end if (!hasSavedStudent) ...[ BEFORE _studentPinController, 
# and start a NEW if (!hasSavedStudent) ...[ AFTER _studentPinController.

# Let's just do text replacement.

s_search = '''              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _studentPinController,'''

s_replace = '''              ],
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _studentPinController,'''

code = code.replace(s_search, s_replace)


s_search2 = '''                ],
              ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _studentRePinController,'''
                  
s_replace2 = '''                ],
              ),
              if (!hasSavedStudent) ...[
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _studentRePinController,'''
                  
code = code.replace(s_search2, s_replace2)


# 2. Admin Portal
a_search = '''              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _adminPasswordController,'''

a_replace = '''              ],
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _adminPasswordController,'''

code = code.replace(a_search, a_replace)


a_search2 = '''                isStudent: false,
              ),
              const SizedBox(height: 20),
              // Email Verification Field for Admin'''

a_replace2 = '''                isStudent: false,
                inputFormatters: [LengthLimitingTextInputFormatter(8)],
              ),
              if (!hasSavedAdmin) ...[
              const SizedBox(height: 20),
              // Email Verification Field for Admin'''

code = code.replace(a_search2, a_replace2)


with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("UI fixed")
