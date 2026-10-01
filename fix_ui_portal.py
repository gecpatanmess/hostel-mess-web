import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Student UI
student_ui_search = '''              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _studentPinController,
                label: "8 Character Password",
                hintText: "Enter 8-character Password",
                icon: Icons.dialpad,
                isStudent: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    8,
                  ), // strictly limits to 8 characters
                ],
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _studentRePinController,
                label: "Re-enter Password",'''

student_ui_replace = '''              ], // End of !hasSavedStudent block
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _studentPinController,
                label: "8 Character Password",
                hintText: "Enter 8-character password",
                icon: Icons.dialpad,
                isStudent: true,
                inputFormatters: [LengthLimitingTextInputFormatter(8)],
              ),
              const SizedBox(height: 20),
              if (!hasSavedStudent) ...[
              _buildPasswordField(
                controller: _studentRePinController,
                label: "Re-enter Password",'''

code = code.replace(student_ui_search, student_ui_replace)


# 2. Admin UI
admin_ui_search = '''              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _adminPasswordController,
                label: "8 Character Password",
                hintText: "Enter 8-character password",
                icon: Icons.lock_outline,
                isStudent: false,
                inputFormatters: [LengthLimitingTextInputFormatter(8)],
              ),
              const SizedBox(height: 20),
              // Email Verification Field for Admin'''

admin_ui_replace = '''              ], // End of !hasSavedAdmin block
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _adminPasswordController,
                label: "8 Character Password",
                hintText: "Enter 8-character password",
                icon: Icons.lock_outline,
                isStudent: false,
                inputFormatters: [LengthLimitingTextInputFormatter(8)],
              ),
              const SizedBox(height: 20),
              if (!hasSavedAdmin) ...[
              // Email Verification Field for Admin'''

code = code.replace(admin_ui_search, admin_ui_replace)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("UI fixed")
