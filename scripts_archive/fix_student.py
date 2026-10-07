import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    code = f.read()

# 1. Student Portal
# We wrap everything from _buildDropdownField() to the end of Email Verification in `if (!hasSavedStudent) ...[`
student_re = re.search(r'(\s+const SizedBox\(height: 32\),\s+)(_buildDropdownField\(\),)', code)
if student_re:
    replacement = r'''\1if (hasSavedStudent) ...[
                Center(child: Text(savedStudentName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
                Center(child: Text("Room: ${savedStudentRoom ?? ''}", style: const TextStyle(fontSize: 14, color: brandGray))),
              ],
              if (!hasSavedStudent) ...[
              \2'''
    code = code.replace(student_re.group(0), student_re.expand(replacement))

# Find the end of Email verification for student
student_email_end_re = re.search(r'(isStudentForm: true\),\s+style: ElevatedButton\.styleFrom\(.*?child: _isVerifyingEmail.*?_studentEmailVerified \? "Verified \?\?" : "Verify",.*?,\s+\),\s+\),\s+],\s+\),\s+],\s+\),\s+)(const SizedBox\(height: 36\),\s+SizedBox\(\s+width: double\.infinity,\s+height: 58,\s+child: ElevatedButton\(\s+onPressed: _handleStudentLogin,)', code, re.DOTALL)

if student_email_end_re:
    replacement = r'''\1], // End of if (!hasSavedStudent)
              if (hasSavedStudent) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword(true),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearSavedStudent,
                    child: const Text("Not You?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              \2'''
    code = code.replace(student_email_end_re.group(0), student_email_end_re.expand(replacement))

# 2. Admin Portal
admin_re = re.search(r'(\s+const SizedBox\(height: 32\),\s+)(Column\(\s+crossAxisAlignment: CrossAxisAlignment\.start,\s+children: \[\s+const Text\(\s+"Mobile Number",)', code)
if admin_re:
    replacement = r'''\1if (hasSavedAdmin) ...[
                Center(child: Text(savedAdminName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
                Center(child: Text("Phone: ${savedAdminPhone ?? ''}", style: const TextStyle(fontSize: 14, color: brandGray))),
              ],
              if (!hasSavedAdmin) ...[
              \2'''
    code = code.replace(admin_re.group(0), admin_re.expand(replacement))

# Find the end of Email verification for admin
admin_email_end_re = re.search(r'(isStudentForm: false\),\s+style: ElevatedButton\.styleFrom\(.*?child: _isVerifyingEmail.*?_adminEmailVerified \? "Verified \?\?" : "Verify",.*?,\s+\),\s+\),\s+],\s+\),\s+],\s+\),\s+)(const SizedBox\(height: 36\),\s+SizedBox\(\s+width: double\.infinity,\s+height: 58,\s+child: ElevatedButton\(\s+onPressed: _handleAdminLogin,)', code, re.DOTALL)

if admin_email_end_re:
    replacement = r'''\1], // End of if (!hasSavedAdmin)
              if (hasSavedAdmin) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword(false),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearSavedAdmin,
                    child: const Text("Not You?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              \2'''
    code = code.replace(admin_email_end_re.group(0), admin_email_end_re.expand(replacement))


with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(code)

print("regex fix complete")
