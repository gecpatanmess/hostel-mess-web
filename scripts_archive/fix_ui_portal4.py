import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix Admin password field missing inputFormatters
admin_pass_old = '''              _buildPasswordField(
                controller: _adminPasswordController,
                label: "Secure Password",
                hintText: "Enter your password",
                icon: Icons.lock_outline,
                isStudent: false,
              ),'''

admin_pass_new = '''              _buildPasswordField(
                controller: _adminPasswordController,
                label: "8 Character Password",
                hintText: "Enter 8-character password",
                icon: Icons.lock_outline,
                isStudent: false,
                inputFormatters: [LengthLimitingTextInputFormatter(8)],
              ),'''

code = code.replace(admin_pass_old, admin_pass_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Admin password fixed")
