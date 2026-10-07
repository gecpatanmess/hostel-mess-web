import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

student_search = '''              const SizedBox(height: 32),
              _buildDropdownField(),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Full Name",'''
                    
student_replace = '''              if (hasSavedStudent) ...[
                const SizedBox(height: 32),
                Center(child: Text(savedStudentName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
                Center(child: Text("Room: ", style: const TextStyle(fontSize: 14, color: brandGray))),
              ],
              if (!hasSavedStudent) ...[
                const SizedBox(height: 32),
                _buildDropdownField(),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Full Name",'''

code = code.replace(student_search, student_replace)

# Now close the if (!hasSavedStudent) ...[ after the re-enter password and email verification.
# Where is the end of Email verification for student?
email_student_search = '''                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _handleStudentLogin,'''

email_student_replace = '''                      ),
                    ],
                  ),
                ],
              ),
              ], // End of if (!hasSavedStudent)
              
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
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _handleStudentLogin,'''

code = code.replace(email_student_search, email_student_replace)


admin_search = '''              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mobile Number",'''

admin_replace = '''              if (hasSavedAdmin) ...[
                const SizedBox(height: 32),
                Center(child: Text(savedAdminName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
                Center(child: Text("Phone: ", style: const TextStyle(fontSize: 14, color: brandGray))),
              ],
              if (!hasSavedAdmin) ...[
                const SizedBox(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Mobile Number",'''

code = code.replace(admin_search, admin_replace)

email_admin_search = '''                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _handleAdminLogin,'''

email_admin_replace = '''                      ),
                    ],
                  ),
                ],
              ),
              ], // End of if (!hasSavedAdmin)
              
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
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _handleAdminLogin,'''

code = code.replace(email_admin_search, email_admin_replace)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Applied fix for Student and Admin portals.")
