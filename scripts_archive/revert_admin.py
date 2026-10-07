with open("lib/main.dart", "r", encoding="utf-8") as f:
    code = f.read()

# Fix the broken admin portal End block
broken_end = """              ], // End of hasSavedAdmin
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
                  onPressed: _handleAdminLogin,"""

good_end = """              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _handleAdminLogin,"""

code = code.replace(broken_end, good_end)

# Also fix the student portal End block if it doesn't compile due to missing commas
# Wait, student portal WAS correctly injected with `if (!hasSavedStudent) ...[`, but let's just make it perfect without python regex magic. Let's write the whole _buildStudentPortal and _buildAdminPortal logic using a script that generates the replacement file securely, or just fix the missing `if (!hasSavedAdmin)` for admin.

admin_start_broken = """            const SizedBox(height: 32),
            _buildInputField(
              controller: _adminMobileController,
              label: "Mobile Number","""
              
admin_start_fixed = """            const SizedBox(height: 32),
            if (hasSavedAdmin) ...[
              Center(child: Text(savedAdminName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
              Center(child: Text("Phone: ${savedAdminPhone ?? ''}", style: const TextStyle(fontSize: 14, color: brandGray))),
              const SizedBox(height: 20),
            ],
            if (!hasSavedAdmin) ...[
            _buildInputField(
              controller: _adminMobileController,
              label: "Mobile Number","""

code = code.replace(admin_start_broken, admin_start_fixed)

admin_end_re_broken = """                            : Text(
                                _adminEmailVerified ? "Verified ✓" : "Verify",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _handleAdminLogin,"""
                
admin_end_re_fixed = """                            : Text(
                                _adminEmailVerified ? "Verified ✓" : "Verify",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ], // End of !hasSavedAdmin
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _handleForgotPassword(false),
                child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
              ),
            ),
            if (hasSavedAdmin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _clearSavedAdmin,
                  child: const Text("Not You?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _handleAdminLogin,"""

code = code.replace(admin_end_re_broken, admin_end_re_fixed)


# Same robust rewrite for Student End Block to be completely safe:
student_end_broken = """                            : Text(
                                _studentEmailVerified ? "Verified ✓" : "Verify",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),              ], // End of hasSavedStudent
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
                  onPressed: _handleStudentLogin,"""
                  
student_end_fixed = """                            : Text(
                                _studentEmailVerified ? "Verified ✓" : "Verify",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ], // End of !hasSavedStudent
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _handleForgotPassword(true),
                child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
              ),
            ),
            if (hasSavedStudent)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _clearSavedStudent,
                  child: const Text("Not You?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _handleStudentLogin,"""

code = code.replace(student_end_broken, student_end_fixed)


with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(code)

print("done")
