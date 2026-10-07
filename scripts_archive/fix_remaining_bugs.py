import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Bug 2: pushMenu Data Loss Bug
code = code.replace(
    "if (globalMenuFile == null) {\n      await _dbRef.child('menu').remove();\n      await _supabase.from('menu').delete().eq('id', 1);\n      return;\n    }",
    "if (globalMenuFile == null && globalMenuUploadBytes == null && globalMenuUrl == null) {\n      await _dbRef.child('menu').remove();\n      await _supabase.from('menu').delete().eq('id', 1);\n      return;\n    }"
)

# Fix readAsBytes in pushMenu
code = code.replace(
    "String base64Image = base64Encode(await globalMenuFile!.readAsBytes());",
    "String base64Image = '';\n    if (globalMenuUploadBytes != null) {\n      base64Image = base64Encode(globalMenuUploadBytes!);\n    } else if (globalMenuFile != null) {\n      base64Image = base64Encode(await globalMenuFile!.readAsBytes());\n    }"
)
code = code.replace(
    "'fileBase64': base64Image,\n      'isPdf': false",
    "'fileBase64': base64Image,\n      'isPdf': globalMenuIsPdf"
)

# Bug 3: ViewMenuTab null assertion crash
view_menu_tab_old = '''    if (globalMenuFile == null) {
      return const Center(
        child: Text(
          "No menu uploaded yet.",
          style: TextStyle(color: brandGray),
        ),
      );
    }
    if (globalMenuIsPdf) {
      return SfPdfViewer.file(globalMenuFile!);
    } else {
      return InteractiveViewer(
        child: Center(child: (globalMenuFile! == null || kIsWeb) ? const Icon(Icons.image, size: 50) : Image.file(globalMenuFile!)),
      );
    }'''
view_menu_tab_new = '''    if (globalMenuFile == null && globalMenuUploadBytes == null && globalMenuUrl == null) {
      return const Center(
        child: Text("No menu uploaded yet.", style: TextStyle(color: brandGray)),
      );
    }
    if (globalMenuIsPdf) {
      if (globalMenuUploadBytes != null) {
        return SfPdfViewer.memory(globalMenuUploadBytes!);
      } else if (globalMenuUrl != null && globalMenuUrl!.isNotEmpty && globalMenuUrl!.startsWith('http')) {
        return SfPdfViewer.network(globalMenuUrl!);
      } else if (globalMenuFile != null) {
        return SfPdfViewer.file(globalMenuFile!);
      }
    }
    
    // Image
    if (globalMenuUploadBytes != null) {
      return InteractiveViewer(child: Center(child: Image.memory(globalMenuUploadBytes!)));
    } else if (globalMenuUrl != null && globalMenuUrl!.isNotEmpty && globalMenuUrl!.startsWith('http')) {
      return InteractiveViewer(child: Center(child: Image.network(globalMenuUrl!)));
    } else if (globalMenuFile != null && !kIsWeb) {
      return InteractiveViewer(child: Center(child: Image.file(globalMenuFile!)));
    }
    return const Center(child: Icon(Icons.image, size: 50));'''
code = code.replace(view_menu_tab_old, view_menu_tab_new)

# Bug 4, 5, 7, 10: Let's fix student login flow
target_student_login = '''        if (existingStudent.pin.isEmpty) {
          if (typedPin.length < 8) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be 8 characters'), backgroundColor: Colors.redAccent));
            return;
          }
          if (typedPin != _studentRePinController.text) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
            return;
          }
          existingStudent.pin = typedPin;
          existingStudent.email = _studentEmailController.text.trim();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Password created successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (existingStudent.pin != typedPin) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid password'), backgroundColor: Colors.redAccent));
          return;
        }

        if (studentPhotoUrl != null) {
          existingStudent.photoUrl = studentPhotoUrl;
        }
        await saveRegisteredStudents();
        SyncService.pushStudents();
      } else {
        if (studentPhotoUrl == null && !hasSavedStudent) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a photo.'), backgroundColor: Colors.redAccent));
          return;
        }
        if (typedPin != _studentRePinController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
          return;
        }
        globalRegisteredStudents.add(
          RegisteredStudent(typedName, selectedRoom!, studentPhotoUrl, typedPin, email: _studentEmailController.text.trim()),
        );
        await saveRegisteredStudents();
        SyncService.pushStudents();
      }'''

replacement_student_login = '''        if (existingStudent.pin.isEmpty) {
          if (typedPin.length < 8) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be 8 characters'), backgroundColor: Colors.redAccent));
            return;
          }
          if (typedPin != _studentRePinController.text) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
            return;
          }
          existingStudent.pin = hashedTypedPin;
          existingStudent.email = _studentEmailController.text.trim();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password created successfully!', style: TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.green),
          );
        } else if (existingStudent.pin != hashedTypedPin && existingStudent.pin != typedPin) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid password'), backgroundColor: Colors.redAccent));
          return;
        }

        if (studentPhotoUrl != null) {
          existingStudent.photoUrl = studentPhotoUrl;
        }
        await saveRegisteredStudents();
        SyncService.pushStudents();
      } else {
        if (studentPhotoUrl == null && !hasSavedStudent) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a photo.'), backgroundColor: Colors.redAccent));
          return;
        }
        if (typedPin.length < 8) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be 8 characters'), backgroundColor: Colors.redAccent));
          return;
        }
        if (typedPin != _studentRePinController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
          return;
        }
        globalRegisteredStudents.add(
          RegisteredStudent(typedName, selectedRoom!, studentPhotoUrl, hashedTypedPin, email: _studentEmailController.text.trim()),
        );
        await saveRegisteredStudents();
        SyncService.pushStudents();
      }'''
code = code.replace(target_student_login, replacement_student_login)

# Now fix the UI to not require Re-enter pin for returning students.
re_enter_pin = '''                            const SizedBox(height: 16),
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
                            ),'''
replacement_re_enter_pin = '''                            if (!hasSavedStudent) ...[
                              const SizedBox(height: 16),
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
                                validator: (val) {
                                  if (hasSavedStudent) return null; // No validation needed for returning students
                                  
                                  // Let's check if the student already exists. If yes, they don't need to re-enter pin (unless creating).
                                  // Since we don't have existingStudent here, we'll relax this validation or remove it from the form validation and handle it on submit.
                                  return null;
                                },
                              ),
                            ],'''
code = code.replace(re_enter_pin, replacement_re_enter_pin)

# Fix admin login password hashing
target_admin_login = '''        if (admin.pin != _adminPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Admin Password'), backgroundColor: Colors.redAccent));
          return;
        }'''
replacement_admin_login = '''        if (admin.pin != hashPassword(_adminPasswordController.text) && admin.pin != _adminPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Admin Password'), backgroundColor: Colors.redAccent));
          return;
        }
        
        // Also save admin email if provided during verification
        if (_adminEmailController.text.trim().isNotEmpty && admin.email.isEmpty) {
            admin.email = _adminEmailController.text.trim();
        }'''
code = code.replace(target_admin_login, replacement_admin_login)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Applied fixes for Bugs 2, 3, 4, 7, 8, 10")
