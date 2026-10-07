with open("lib/main.dart", "r", encoding="utf-8") as f:
    code = f.read()

student_search = '''                      ),
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

student_replace = '''                      ),
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

code = code.replace(student_search, student_replace)


admin_search = '''                      ),
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

admin_replace = '''                      ),
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

code = code.replace(admin_search, admin_replace)


with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(code)

print("fix end complete")
