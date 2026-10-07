import re
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# For student:
code = code.replace(
'''              ], // End of if (!hasSavedStudent)
              
              if (hasSavedStudent) ...[''',
'''              ], // End of if (!hasSavedStudent)
              
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword(true),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                  ),
              ),
              if (hasSavedStudent) ...[''')

# For admin:
code = code.replace(
'''              ], // End of if (!hasSavedAdmin)
              
              if (hasSavedAdmin) ...[''',
'''              ], // End of if (!hasSavedAdmin)
              
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword(false),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                  ),
              ),
              if (hasSavedAdmin) ...[''')

# Also remove duplicate Forgot Password inside the hasSaved block to prevent showing it twice
code = code.replace(
'''                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword(true),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearSavedStudent,''',
'''                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearSavedStudent,''')

code = code.replace(
'''                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword(false),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearSavedAdmin,''',
'''                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearSavedAdmin,''')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Applied fix for Forgot Password.")
