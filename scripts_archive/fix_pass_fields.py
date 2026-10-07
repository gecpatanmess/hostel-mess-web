import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

admin_pass = '''              _buildPasswordField(
                controller: _adminPasswordController,
                label: "Secure Password",
                hintText: "Enter your password",
                icon: Icons.lock_outline,
                isStudent: false,
              ),'''
              
admin_pass_fixed = '''              _buildPasswordField(
                controller: _adminPasswordController,
                label: "8 Character Password",
                hintText: "Enter 8-character password",
                icon: Icons.lock_outline,
                isStudent: false,
                inputFormatters: [LengthLimitingTextInputFormatter(8)],
              ),'''

code = code.replace(admin_pass, admin_pass_fixed)

admin_create_pass = '''                    _buildInputField(
                      controller: _newAdminPinCtrl,
                      label: "Password",
                      hintText: "Enter secure password",
                      icon: Icons.lock_outline,
                    ),'''
                    
admin_create_pass_fixed = '''                    _buildInputField(
                      controller: _newAdminPinCtrl,
                      label: "8 Character Password",
                      hintText: "Enter 8-character password",
                      icon: Icons.lock_outline,
                      inputFormatters: [LengthLimitingTextInputFormatter(8)],
                    ),'''

code = code.replace(admin_create_pass, admin_create_pass_fixed)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("pass fields fixed")
