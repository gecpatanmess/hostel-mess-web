import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    code = f.read()

def inject_after_email(code, search_func_str, block_var, is_student):
    # Find the button block
    pattern = r'(\s+const SizedBox\(height: 36\),\s+SizedBox\(\s+width: double\.infinity,\s+height: 58,\s+child: ElevatedButton\(\s+onPressed: )' + search_func_str
    
    replacement = f'''              ], // End of {block_var}
              if ({block_var}) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword({"true" if is_student else "false"}),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: {"_clearSavedStudent" if is_student else "_clearSavedAdmin"},
                    child: const Text("Not You?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],\\1{search_func_str}'''
    return re.sub(pattern, replacement, code, count=1)

code = inject_after_email(code, '_handleStudentLogin', 'hasSavedStudent', True)
code = inject_after_email(code, '_handleAdminLogin', 'hasSavedAdmin', False)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(code)

print("regex fix 3 complete")
