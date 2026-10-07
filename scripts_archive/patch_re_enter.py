import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

# I will find the exact string to replace by regex
pattern = r"_buildPasswordField\(\s*controller:\s*_studentPinController,.*?isStudent:\s*true,.*?inputFormatters:.*?\[.*?LengthLimitingTextInputFormatter\(\s*8\s*,\s*\).*?\],\s*\),"

match = re.search(pattern, code, re.DOTALL)
if match:
    matched_text = match.group(0)
    new_text = matched_text + """
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _studentRePinController,
                label: "Re-enter Password",
                hintText: "Re-enter 8-character Password",
                icon: Icons.lock_outline,
                isStudent: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(8),
                ],
              ),"""
    code = code.replace(matched_text, new_text)
    with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
    print("Re-enter password field injected!")
else:
    print("Pattern not found!")
