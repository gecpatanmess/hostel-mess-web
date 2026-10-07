"""
Implementation Plan v4 - Master Patch Script
ALL changes applied via exact string matching. NO regex.
"""

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

changes_applied = 0

# =====================================================
# 1. Add image_cropper import
# =====================================================
if "import 'package:image_cropper/image_cropper.dart';" not in text:
    text = text.replace(
        "import 'package:image_picker/image_picker.dart';",
        "import 'package:image_picker/image_picker.dart';\nimport 'package:image_cropper/image_cropper.dart';"
    )
    changes_applied += 1
    print("1. Added image_cropper import")

# =====================================================
# 2. Update AuthStage enum - add adminEmail stage
# =====================================================
old_enum = "enum AuthStage { identifier, standardPassword, newPassword, personalPassword, otp }"
new_enum = "enum AuthStage { identifier, standardPassword, adminEmail, newPassword, personalPassword, otp }"
if old_enum in text:
    text = text.replace(old_enum, new_enum)
    changes_applied += 1
    print("2. Updated AuthStage enum with adminEmail stage")

# =====================================================
# 3. Add password validation function (before _pickImage)
# =====================================================
password_validator = '''
  String? _validatePassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (password.length > 16) return 'Password must be at most 16 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Must contain at least 1 uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Must contain at least 1 number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return 'Must contain at least 1 special character';
    return null;
  }

'''
if "_validatePassword" not in text:
    text = text.replace(
        "  Future<void> _pickImage(bool isStudentForm) async {",
        password_validator + "  Future<void> _pickImage(bool isStudentForm) async {"
    )
    changes_applied += 1
    print("3. Added _validatePassword function")

# =====================================================
# 4. Update _pickImage to add circular cropping
# =====================================================
old_pick_image = """  Future<void> _pickImage(bool isStudentForm) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
        maxWidth: 800,
      );
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading photo... Please wait.'), duration: Duration(seconds: 2)));
        final bytes = await image.readAsBytes();
        final url = await SyncService.uploadImage(bytes);
        if (url != null) {
          setState(() {
            if (isStudentForm) {
              studentPhotoUrl = url;
            } else {
              adminPhotoUrl = url;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed (Storage Error). Check bucket policies.')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }"""

new_pick_image = """  Future<void> _pickImage(bool isStudentForm) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (image == null) return;
      
      // Circular crop
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        cropStyle: CropStyle.circle,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: const Color(0xFFE86A33),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop Photo'),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 400, height: 400),
          ),
        ],
      );
      if (croppedFile == null) return;
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading photo... Please wait.'), duration: Duration(seconds: 2)));
      final bytes = await croppedFile.readAsBytes();
      final url = await SyncService.uploadImage(bytes);
      if (url != null) {
        setState(() {
          if (isStudentForm) {
            studentPhotoUrl = url;
          } else {
            adminPhotoUrl = url;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed (Storage Error). Check bucket policies.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \\$e')));
    }
  }"""

if old_pick_image in text:
    text = text.replace(old_pick_image, new_pick_image)
    changes_applied += 1
    print("4. Updated _pickImage with circular cropping")
else:
    print("4. WARNING: Could not find _pickImage to replace (may already be updated)")

# =====================================================
# 5. Replace _verifyIdentifierStage to search BOTH databases
# =====================================================
old_verify_start = "  Future<void> _verifyIdentifierStage() async {"
old_verify_end = "    }\n  }\n\n  Future<void> _handleUnifiedAction() async {"
# Find the exact block
idx_start = text.find(old_verify_start)
idx_end = text.find("  Future<void> _handleUnifiedAction() async {")

new_verify_and_action = '''  Future<void> _verifyIdentifierStage() async {
    String input = _studentEmailController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Email or Mobile Number')));
      return;
    }
    setState(() => _isVerifyingEmail = true);
    
    bool isNumeric = RegExp(r'^[0-9]+$').hasMatch(input) && input.length == 10;
    
    if (isNumeric) {
      // === ADMIN FLOW ===
      _isAdminFlow = true;
      _matchedAdmin = null;
      
      // Search BOTH boys and girls admin databases
      for (String mode in ['boys', 'girls']) {
        try {
          final snap = await FirebaseDatabase.instance.ref('hostelData_$mode/admins').get();
          if (snap.exists && snap.value != null) {
            List<AdminUser> tempAdmins = [];
            for (var a in (snap.value as List)) {
              if (a != null) {
                tempAdmins.add(AdminUser.fromJson(Map<String, dynamic>.from(a)));
              }
            }
            for (var a in tempAdmins) {
              if (a.phone == input) {
                _matchedAdmin = a;
                globalHostelMode = mode;
                globalAdmins = tempAdmins;
                break;
              }
            }
          }
        } catch (e) {}
        if (_matchedAdmin != null) break;
      }
      
      if (_matchedAdmin == null) {
        setState(() => _isVerifyingEmail = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email/number not registered. Please contact Admin.')));
        return;
      }
      
      setState(() {
        _isVerifyingEmail = false;
        if (_matchedAdmin!.pin.isNotEmpty && _matchedAdmin!.pin != 'Hostel@123' && _matchedAdmin!.pin != hashPassword('Hostel@123')) {
           _authStage = AuthStage.personalPassword;
           adminPhotoUrl = _matchedAdmin!.photoUrl;
        } else {
           _authStage = AuthStage.standardPassword;
        }
      });
      return;
    }

    // === STUDENT FLOW ===
    _isAdminFlow = false;
    String email = input.toLowerCase();
    if (!email.contains('@')) {
      setState(() => _isVerifyingEmail = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Email format')));
      return;
    }
    
    // Search BOTH boys and girls student databases
    _matchedStudent = null;
    for (String mode in ['boys', 'girls']) {
      try {
        final snap = await FirebaseDatabase.instance.ref('hostelData_$mode/students').get();
        if (snap.exists && snap.value != null) {
          List<RegisteredStudent> tempStudents = [];
          for (var s in (snap.value as List)) {
            if (s != null) {
              var st = RegisteredStudent.fromJson(Map<String, dynamic>.from(s));
              if (st.isValid) tempStudents.add(st);
            }
          }
          for (var s in tempStudents) {
            if (s.email != null && s.email.toLowerCase() == email) {
              _matchedStudent = s;
              globalHostelMode = mode;
              globalRegisteredStudents = tempStudents;
              break;
            }
          }
        }
      } catch (e) {}
      if (_matchedStudent != null) break;
    }
    
    if (_matchedStudent == null) {
      setState(() => _isVerifyingEmail = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email not registered. Please contact Admin.')));
      return;
    }
    
    if (_matchedStudent!.pin.isNotEmpty) {
      setState(() {
        _isVerifyingEmail = false;
        _authStage = AuthStage.personalPassword;
        studentPhotoUrl = _matchedStudent!.photoUrl;
        selectedStudentName = _matchedStudent!.name;
        selectedRoom = _matchedStudent!.roomNo;
      });
    } else {
      Map<String, dynamic> res = await EmailOtpService.sendOtp(email);
      bool sent = res['success'] == true;
      setState(() => _isVerifyingEmail = false);
      if (sent) {
        bool verified = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _OtpVerificationDialog(email: email),
        ) ?? false;
        if (verified) {
          setState(() {
            _authStage = AuthStage.newPassword;
            selectedStudentName = _matchedStudent!.name;
            selectedRoom = _matchedStudent!.roomNo;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send OTP.')));
      }
    }
  }

  Future<void> _handleUnifiedAction() async {
    String typedPin = _studentPinController.text.trim();
    
    if (_isAdminFlow) {
      if (_authStage == AuthStage.standardPassword) {
        if (typedPin != 'Hostel@123') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Standard Password!')));
          return;
        }
        // Standard password correct -> show email input
        setState(() {
          _authStage = AuthStage.adminEmail;
          _studentPinController.clear();
        });
      } else if (_authStage == AuthStage.adminEmail) {
        // Verify admin email matches
        String enteredEmail = _adminEmailController.text.trim().toLowerCase();
        if (enteredEmail.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email')));
          return;
        }
        if (_matchedAdmin!.email.toLowerCase() != enteredEmail) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email does not match. Access denied.')));
          return;
        }
        // Email matches -> send OTP
        setState(() => _isVerifyingEmail = true);
        Map<String, dynamic> res = await EmailOtpService.sendOtp(enteredEmail);
        bool sent = res['success'] == true;
        setState(() => _isVerifyingEmail = false);
        if (sent) {
          bool verified = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => _OtpVerificationDialog(email: enteredEmail),
          ) ?? false;
          if (verified) {
            if (_matchedAdmin!.pin.isNotEmpty && _matchedAdmin!.pin != 'Hostel@123' && _matchedAdmin!.pin != hashPassword('Hostel@123')) {
              setState(() {
                _authStage = AuthStage.personalPassword;
                adminPhotoUrl = _matchedAdmin!.photoUrl;
                _studentPinController.clear();
              });
            } else {
              setState(() {
                _authStage = AuthStage.newPassword;
                _studentPinController.clear();
              });
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send OTP.')));
        }
      } else if (_authStage == AuthStage.personalPassword) {
        String hashed = hashPassword(typedPin);
        if (_matchedAdmin!.pin == typedPin || _matchedAdmin!.pin == hashed) {
          await _finalizeAdminLogin(_matchedAdmin!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Password!')));
        }
      } else if (_authStage == AuthStage.newPassword) {
         String? validationError = _validatePassword(typedPin);
         if (validationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError)));
            return;
         }
         if (typedPin != _studentRePinController.text) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
            return;
         }
         if (studentPhotoUrl == null || studentPhotoUrl!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload photo first!')));
            return;
         }
         _matchedAdmin!.pin = hashPassword(typedPin);
         _matchedAdmin!.photoUrl = studentPhotoUrl;
         
         int idx = globalAdmins.indexWhere((a) => a.phone == _matchedAdmin!.phone);
         if (idx != -1) globalAdmins[idx] = _matchedAdmin!;
         
         final p = await SharedPreferences.getInstance();
         await p.setStringList('globalAdmins', globalAdmins.map((a) => jsonEncode(a.toJson())).toList());
         await SyncService.pushAdmins();
         
         await _finalizeAdminLogin(_matchedAdmin!);
      }
      return;
    }
    
    // === STUDENT LOGIC ===
    if (_authStage == AuthStage.newPassword) {
      String? validationError = _validatePassword(typedPin);
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError)));
        return;
      }
      if (typedPin != _studentRePinController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
        return;
      }
      if (studentPhotoUrl == null || studentPhotoUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your photo to complete registration.')));
        return;
      }
      
      _matchedStudent!.pin = hashPassword(typedPin);
      _matchedStudent!.photoUrl = studentPhotoUrl;
      
      int idx = globalRegisteredStudents.indexWhere((s) => s.name == _matchedStudent!.name && s.roomNo == _matchedStudent!.roomNo);
      if (idx != -1) {
        globalRegisteredStudents[idx] = _matchedStudent!;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving profile...')));
      await saveRegisteredStudents();
      await SyncService.pushStudents();
      
      await _finalizeStudentLogin(_matchedStudent!);
    } else {
      // personalPassword stage
      String hashed = hashPassword(typedPin);
      RegisteredStudent? target = _matchedStudent;
      
      if (hasSavedStudent) {
        try {
          target = globalRegisteredStudents.firstWhere((s) => s.name == savedStudentName && s.roomNo == savedStudentRoom);
        } catch(e) {}
      }
      
      if (target != null && (target.pin == typedPin || target.pin == hashed)) {
        if (target.pin == typedPin) {
          target.pin = hashed;
          int idx = globalRegisteredStudents.indexWhere((s) => s.name == target!.name && s.roomNo == target.roomNo);
          if (idx != -1) globalRegisteredStudents[idx] = target;
          await saveRegisteredStudents();
          await SyncService.pushStudents();
        }
        await _finalizeStudentLogin(target);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Password')));
      }
    }
  }

'''

if idx_start != -1 and idx_end != -1:
    text = text[:idx_start] + new_verify_and_action + text[idx_end:]
    changes_applied += 1
    print("5. Replaced _verifyIdentifierStage and _handleUnifiedAction")
else:
    print(f"5. WARNING: Could not find methods (start={idx_start}, end={idx_end})")

# =====================================================
# 6. Replace _buildStudentPortal with unified login form
# =====================================================
old_portal_start = text.find("  Widget _buildStudentPortal() {")
old_portal_end = text.find("\n\n  Widget _buildAdminPortal() {", old_portal_start)
if old_portal_end == -1:
    old_portal_end = text.find("\n  Widget _buildAdminPortal() {", old_portal_start)

new_unified_portal = '''  Widget _buildStudentPortal() {
    return Container(
      key: const ValueKey("UnifiedLogin"),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _studentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.login, color: Color(0xFFE86A33), size: 22),
                SizedBox(width: 10),
                Text(
                  "Login",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E)),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // === STAGE: IDENTIFIER (Email or Mobile) ===
            if (_authStage == AuthStage.identifier && !hasSavedStudent && !hasSavedAdmin) ...[
              const Text("Registered Email / Mobile", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter registered email or mobile number",
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF8A8A8A), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifyingEmail ? null : _verifyIdentifierStage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE86A33),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isVerifyingEmail 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Next", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],

            // === STAGE: STANDARD PASSWORD (Admin only) ===
            if (_authStage == AuthStage.standardPassword) ...[
              const Center(child: Icon(Icons.admin_panel_settings, color: Color(0xFFE86A33), size: 48)),
              const SizedBox(height: 12),
              const Center(child: Text("Admin Verification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)))),
              const SizedBox(height: 24),
              const Text("Standard Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentPinController,
                obscureText: !isStudentPinVisible,
                decoration: InputDecoration(
                  hintText: "Enter standard password",
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8A8A8A), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(isStudentPinVisible ? Icons.visibility : Icons.visibility_off, color: Color(0xFF8A8A8A), size: 20),
                    onPressed: () => setState(() => isStudentPinVisible = !isStudentPinVisible),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButton("Verify", _handleUnifiedAction),
              const SizedBox(height: 12),
              _buildBackButton(),
            ],

            // === STAGE: ADMIN EMAIL (after standard password) ===
            if (_authStage == AuthStage.adminEmail) ...[
              const Center(child: Icon(Icons.email, color: Color(0xFFE86A33), size: 48)),
              const SizedBox(height: 12),
              const Center(child: Text("Email Verification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)))),
              const SizedBox(height: 24),
              const Text("Your Registered Email", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _adminEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter your registered email",
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF8A8A8A), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButton("Send OTP", _handleUnifiedAction),
              const SizedBox(height: 12),
              _buildBackButton(),
            ],

            // === STAGE: PERSONAL PASSWORD / NEW PASSWORD / QUICK LOGIN ===
            if (_authStage == AuthStage.personalPassword || _authStage == AuthStage.newPassword || hasSavedStudent || hasSavedAdmin) ...[
              if (_authStage != AuthStage.personalPassword && _authStage != AuthStage.newPassword && (hasSavedStudent || hasSavedAdmin)) ...[
                // Quick login for saved user
              ],
              Center(
                child: Column(
                  children: [
                    if (_authStage == AuthStage.newPassword) ...[
                      GestureDetector(
                        onTap: () => _pickImage(true),
                        child: Stack(
                          children: [
                            Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE9D2), shape: BoxShape.circle,
                                image: (studentPhotoUrl != null && studentPhotoUrl!.isNotEmpty)
                                  ? DecorationImage(image: NetworkImage(studentPhotoUrl!), fit: BoxFit.cover) : null,
                              ),
                              child: (studentPhotoUrl == null || studentPhotoUrl!.isEmpty)
                                  ? const Icon(Icons.camera_alt_outlined, color: Color(0xFFE86A33), size: 38) : null,
                            ),
                            Positioned(
                              bottom: 2, right: 2,
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: const Color(0xFFE86A33), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3.0)),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Upload Photo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8A8A8A))),
                    ] else ...[
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: const Color(0xFFF5F5F5),
                          image: (() {
                            String? photo = _isAdminFlow ? adminPhotoUrl : (studentPhotoUrl ?? savedStudentPhoto);
                            return (photo != null && photo.isNotEmpty) ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover) : null;
                          })(),
                        ),
                        child: (() {
                          String? photo = _isAdminFlow ? adminPhotoUrl : (studentPhotoUrl ?? savedStudentPhoto);
                          return (photo == null || photo.isEmpty) ? const Icon(Icons.person, color: Color(0xFF8A8A8A), size: 32) : null;
                        })(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_authStage == AuthStage.newPassword && !_isAdminFlow && _matchedStudent != null) ...[
                      Text(_matchedStudent!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
                      Text("Room: ${_matchedStudent!.roomNo}", style: const TextStyle(fontSize: 14, color: Color(0xFF8A8A8A))),
                    ] else if (_isAdminFlow || hasSavedAdmin) ...[
                      const Text("Admin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
                    ] else ...[
                      Text(
                        hasSavedStudent ? (savedStudentName ?? "Student") : (_matchedStudent?.name ?? selectedStudentName ?? "Student"),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentPinController,
                obscureText: !isStudentPinVisible,
                maxLength: 16,
                decoration: InputDecoration(
                  hintText: _authStage == AuthStage.newPassword ? "Create password (8-16 chars)" : "Enter password",
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8A8A8A), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(isStudentPinVisible ? Icons.visibility : Icons.visibility_off, color: Color(0xFF8A8A8A), size: 20),
                    onPressed: () => setState(() => isStudentPinVisible = !isStudentPinVisible),
                  ),
                  filled: true, fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  counterText: "",
                ),
              ),
              
              if (_authStage == AuthStage.newPassword) ...[
                const SizedBox(height: 6),
                _buildPasswordHints(_studentPinController.text),
                const SizedBox(height: 16),
                const Text("Confirm Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _studentRePinController,
                  obscureText: !isStudentRePinVisible,
                  maxLength: 16,
                  decoration: InputDecoration(
                    hintText: "Re-enter password",
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8A8A8A), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(isStudentRePinVisible ? Icons.visibility : Icons.visibility_off, color: Color(0xFF8A8A8A), size: 20),
                      onPressed: () => setState(() => isStudentRePinVisible = !isStudentRePinVisible),
                    ),
                    filled: true, fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    counterText: "",
                  ),
                ),
              ],
              
              if (_authStage == AuthStage.personalPassword || hasSavedStudent || hasSavedAdmin) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword(hasSavedStudent || (!_isAdminFlow && !hasSavedAdmin)),
                    child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFFE86A33), fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              _buildActionButton(
                _authStage == AuthStage.newPassword ? "Complete Registration" : "Login",
                _handleUnifiedAction,
              ),
              const SizedBox(height: 12),
              _buildBackButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isVerifyingEmail ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE86A33),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isVerifyingEmail 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBackButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          if (hasSavedStudent) _clearSavedStudent();
          if (hasSavedAdmin) _clearSavedAdmin();
          setState(() {
            _authStage = AuthStage.identifier;
            _matchedStudent = null;
            _matchedAdmin = null;
            _isAdminFlow = false;
            _studentPinController.clear();
            _studentRePinController.clear();
            _studentEmailController.clear();
            _adminEmailController.clear();
            studentPhotoUrl = null;
            adminPhotoUrl = null;
          });
        },
        child: const Text("← Go back to login / Switch user", style: TextStyle(color: Color(0xFF8A8A8A), decoration: TextDecoration.underline)),
      ),
    );
  }

  Widget _buildPasswordHints(String password) {
    bool hasLength = password.length >= 8 && password.length <= 16;
    bool hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    
    Widget hint(String text, bool ok) => Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.circle_outlined, size: 14, color: ok ? Colors.green : const Color(0xFF8A8A8A)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: ok ? Colors.green : const Color(0xFF8A8A8A))),
      ],
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hint("8-16 characters", hasLength),
        hint("At least 1 uppercase letter", hasUpper),
        hint("At least 1 number", hasNumber),
        hint("At least 1 special character (!@#\\\$%^&*)", hasSpecial),
      ],
    );
  }

'''

if old_portal_start != -1 and old_portal_end != -1:
    text = text[:old_portal_start] + new_unified_portal + text[old_portal_end:]
    changes_applied += 1
    print("6. Replaced _buildStudentPortal with unified login form")
else:
    print(f"6. WARNING: Could not find _buildStudentPortal (start={old_portal_start}, end={old_portal_end})")

# =====================================================
# 7. Add SyncService.switchMode() method
# =====================================================
if "static Future<void> switchMode(String mode) async" not in text:
    switchmode_code = '''
  static Future<void> switchMode(String mode) async {
    globalHostelMode = mode;
    _hasDownloadedOnce = false;
    _lastHash = 0;
    await fetchNow();
  }

'''
    # Insert after _switchCooldown line
    text = text.replace(
        "  static bool _switchCooldown = false;\n  static bool _pollCooldown = false;",
        "  static bool _switchCooldown = false;\n  static bool _pollCooldown = false;\n" + switchmode_code
    )
    changes_applied += 1
    print("7. Added SyncService.switchMode()")

# =====================================================
# 8. Add Boys/Girls Toggle Switch to Admin Dashboard AppBar
# =====================================================
old_appbar_title = '''            title: const Text(
              "Admin Dashboard",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
        centerTitle: true,'''

new_appbar_title = '''            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Admin  ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (globalHostelMode != 'boys') {
                            await SyncService.switchMode('boys');
                            // Let the Future complete before updating UI, but UI is responsive
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: globalHostelMode == 'boys' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text("Boys", style: TextStyle(
                            color: globalHostelMode == 'boys' ? const Color(0xFFE86A33) : Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 13,
                          )),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (globalHostelMode != 'girls') {
                            await SyncService.switchMode('girls');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: globalHostelMode == 'girls' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text("Girls", style: TextStyle(
                            color: globalHostelMode == 'girls' ? const Color(0xFFE86A33) : Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 13,
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        centerTitle: true,'''

if old_appbar_title in text:
    text = text.replace(old_appbar_title, new_appbar_title)
    changes_applied += 1
    print("8. Added Boys/Girls toggle switch in Admin Dashboard AppBar")
else:
    print("8. WARNING: Could not find Admin Dashboard AppBar title")

# =====================================================
# 9. Update _handleForgotPassword to work with unified login
# =====================================================
old_forgot_student_id = """    if (isStudentReq) {
      targetIdentifier = hasSavedStudent ? savedStudentName : selectedStudentName;
      if (targetIdentifier == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your name first.")));
        return;
      }
      try {
        var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name == targetIdentifier);
        emailToSend = existingStudent.email;
      } catch (e) {}
    } else {
      targetIdentifier = hasSavedAdmin ? savedAdminPhone : _adminMobileController.text.trim();
      if (targetIdentifier == null || targetIdentifier.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your mobile number first.")));
        return;
      }
      try {
        var admin = globalAdmins.firstWhere((a) => a.phone == targetIdentifier);
        emailToSend = admin.email;
      } catch(e) {}
    }"""

new_forgot_student_id = """    if (isStudentReq) {
      // Use matched student from unified login or saved credentials
      if (_matchedStudent != null) {
        emailToSend = _matchedStudent!.email;
        targetIdentifier = _matchedStudent!.name;
      } else if (hasSavedStudent && savedStudentName != null) {
        targetIdentifier = savedStudentName;
        try {
          var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name == targetIdentifier);
          emailToSend = existingStudent.email;
        } catch (e) {}
      }
      if (targetIdentifier == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot identify account for password reset.")));
        return;
      }
    } else {
      // Admin flow
      if (_matchedAdmin != null) {
        emailToSend = _matchedAdmin!.email;
        targetIdentifier = _matchedAdmin!.phone;
      } else if (hasSavedAdmin && savedAdminPhone != null) {
        targetIdentifier = savedAdminPhone;
        try {
          var admin = globalAdmins.firstWhere((a) => a.phone == targetIdentifier);
          emailToSend = admin.email;
        } catch(e) {}
      }
      if (targetIdentifier == null || targetIdentifier.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot identify account for password reset.")));
        return;
      }
    }"""

if old_forgot_student_id in text:
    text = text.replace(old_forgot_student_id, new_forgot_student_id)
    changes_applied += 1
    print("9. Updated _handleForgotPassword for unified login")
else:
    print("9. WARNING: Could not find _handleForgotPassword identifier block")

# Update forgot password: change LengthLimitingTextInputFormatter from 8 to 16
text = text.replace(
    "inputFormatters: [LengthLimitingTextInputFormatter(8)],\n                decoration: const InputDecoration(hintText: \"Enter 8-digit new password\")",
    "inputFormatters: [LengthLimitingTextInputFormatter(16)],\n                decoration: const InputDecoration(hintText: \"Enter new password (8-16 chars)\")"
)
text = text.replace(
    "inputFormatters: [LengthLimitingTextInputFormatter(8)],\n                decoration: const InputDecoration(hintText: \"Re-enter password\")",
    "inputFormatters: [LengthLimitingTextInputFormatter(16)],\n                decoration: const InputDecoration(hintText: \"Re-enter password\")"
)
text = text.replace(
    "if (newPassCtrl.text.length != 8) {\n                   ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text(\"Password must be exactly 8 characters\")));",
    "if (newPassCtrl.text.length < 8 || newPassCtrl.text.length > 16) {\n                   ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text(\"Password must be 8-16 characters\")));"
)
print("9b. Updated forgot password dialog for 8-16 chars")

# Also update the save logic in forgot password to use matched references
text = text.replace(
    "          var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name.toLowerCase() == savedStudentName!.toLowerCase());",
    "          var existingStudent = _matchedStudent ?? globalRegisteredStudents.firstWhere((s) => s.name.toLowerCase() == (savedStudentName ?? '').toLowerCase());"
)
text = text.replace(
    "          var admin = globalAdmins.firstWhere((a) => a.phone == savedAdminPhone);",
    "          var admin = _matchedAdmin ?? globalAdmins.firstWhere((a) => a.phone == (savedAdminPhone ?? ''));"
)

# =====================================================
# DONE
# =====================================================
with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print(f"\\n=== SUCCESS: {changes_applied} major patches applied! ===")
