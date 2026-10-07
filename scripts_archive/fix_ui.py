import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Change "Registered Email / Mobile" to "Registered Email"
text = text.replace('const Text("Registered Email / Mobile",', 'const Text("Registered Email",')
text = text.replace('hintText: "Enter registered email or mobile number",', 'hintText: "Enter registered email",')

# 2. Fix the error message interpolation
text = text.replace("Text('Error: \\\\')", "Text('Error: ')")
text = text.replace("Text('Error: \\')", "Text('Error: ')")

# 3. Fix real-time password validation
text = text.replace(
'''                controller: _studentPinController,
                obscureText: !isStudentPinVisible,''',
'''                controller: _studentPinController,
                obscureText: !isStudentPinVisible,
                onChanged: (val) => setState(() {}),'''
)

text = text.replace(
'''                  controller: _studentRePinController,
                  obscureText: !isStudentRePinVisible,''',
'''                  controller: _studentRePinController,
                  obscureText: !isStudentRePinVisible,
                  onChanged: (val) => setState(() {}),'''
)

# 4. Fix Room number display
text = text.replace(
'''                    ] else if (_isAdminFlow || hasSavedAdmin) ...[
                      const Text("Admin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
                    ] else ...[''',
'''                    ] else if (_isAdminFlow || hasSavedAdmin) ...[
                      const Text("Admin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
                    ] else ...[
                      Text(
                        hasSavedStudent ? "Room: " : (_matchedStudent != null ? "Room: " : ""),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
                      ),'''
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Dart fixes applied.")
