import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

ui_patch_student_saved = """                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _handleForgotPassword(true),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange)),
                  )
                ],
              )"""

code = code.replace("""                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _clearSavedStudent,
                    child: const Text("Login with another account", style: TextStyle(color: brandOrange)),
                  )
                ],
              )""", ui_patch_student_saved)

ui_patch_admin_saved = """                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _handleForgotPassword(false),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange)),
                  )
                ],
              )"""

code = code.replace("""                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _clearSavedAdmin,
                    child: const Text("Login with another account", style: TextStyle(color: brandOrange)),
                  )
                ],
              )""", ui_patch_admin_saved)

# Add the re-enter password field for student registration
re_enter_pwd = """                            const SizedBox(height: 16),
                            const Text("Re-enter Password", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: brandDark)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _studentRePinController,
                              obscureText: !isStudentRePinVisible,
                              decoration: InputDecoration(
                                hintText: "Re-enter your password",
                                prefixIcon: const Icon(Icons.lock_outline, color: brandGray),
                                suffixIcon: IconButton(
                                  icon: Icon(isStudentRePinVisible ? Icons.visibility_off : Icons.visibility, color: brandGray),
                                  onPressed: () => setState(() => isStudentRePinVisible = !isStudentRePinVisible),
                                ),
                                filled: true,
                                fillColor: brandInputBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              ),
                              validator: (val) => (val == null || val.length < 8) ? "Enter at least 8 characters" : null,
                            ),"""

# We need to insert this right after the studentPinController in the 'Column(' of '!hasSavedStudent'
code = code.replace("""validator: (val) => (val == null || val.length < 8) ? "Enter at least 8 characters" : null,
                            ),
                            const SizedBox(height: 36),
                            SizedBox(""", """validator: (val) => (val == null || val.length < 8) ? "Enter at least 8 characters" : null,
                            ),""" + re_enter_pwd + """
                            const SizedBox(height: 36),
                            SizedBox(""")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Patching logic part 4 complete")
