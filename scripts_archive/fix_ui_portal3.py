import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Student Pin Controller
code = re.sub(
    r'(?P<space>\s*)(const SizedBox\(height: \d+\),\s*_buildPasswordField\(\s*controller: _studentPinController,)',
    r'\g<space>],\g<space>\g<2>',
    code
)

# Student Re-Pin Controller
code = re.sub(
    r'(?P<space>\s*)(const SizedBox\(height: \d+\),\s*_buildPasswordField\(\s*controller: _studentRePinController,)',
    r'\g<space>if (!hasSavedStudent) ...[\g<space>\g<2>',
    code
)

# Admin Password Controller
code = re.sub(
    r'(?P<space>\s*)(const SizedBox\(height: \d+\),\s*_buildPasswordField\(\s*controller: _adminPasswordController,)',
    r'\g<space>],\g<space>\g<2>',
    code
)

# Admin Email Verification (to open the if block)
code = re.sub(
    r'(?P<space>\s*)(// Email Verification Field for Admin)',
    r'\g<space>if (!hasSavedAdmin) ...[\g<space>\g<2>',
    code
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("UI Regex Fixed")
