import re
import os

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix the broken interpolation first
text = text.replace("'hostelData_/students'", "'hostelData_${globalHostelMode}/students'")

# We need to completely replace _verifyEmailStage and _handleStudentLoginAction and _buildStudentPortal
# and remove _buildAdminPortal from build() method.
# But since the previous code is complex, let's inject a totally new unified login widget!

# 1. First, we need to modify the Enum
if "enum AuthStage" not in text:
    text = text.replace("class _LoginScreenState extends State<LoginScreen> {",
                        "enum AuthStage { identifier, standardPassword, newPassword, personalPassword, otp }\n\nclass _LoginScreenState extends State<LoginScreen> {")
    text = text.replace("bool isStudent = true;",
                        "AuthStage _authStage = AuthStage.identifier;\n  bool _isAdminFlow = false;\n  AdminUser? _matchedAdmin;\n  String _adminVerificationId = '';\n\n  bool isStudent = true;")

# 2. Update the Unified Logic block
unified_logic = """
  Future<void> _verifyIdentifierStage() async {
    String input = _studentEmailController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Email or Mobile Number')));
      return;
    }
    setState(() => _isVerifyingEmail = true);
    
    // Admin Check
    bool isNumeric = RegExp(r'^[0-9]+$').hasMatch(input) && input.length == 10;
    
    if (isNumeric) {
      _isAdminFlow = true;
      try {
        final snap = await FirebaseDatabase.instance.ref('hostelData_${globalHostelMode}/admins').get();
        if (snap.exists && snap.value != null) {
          globalAdmins.clear();
          for(var a in (snap.value as List)) {
            if (a != null) {
              globalAdmins.add(AdminUser.fromJson(Map<String,dynamic>.from(a)));
            }
          }
        }
      } catch(e) {}
      
      _matchedAdmin = null;
      for (var a in globalAdmins) {
        if (a.phone == input) {
          _matchedAdmin = a;
          break;
        }
      }
      
      if (_matchedAdmin == null) {
        setState(() => _isVerifyingEmail = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email not registered. Please contact Admin.'))); // Disguised error
        return;
      }
      
      setState(() {
        _isVerifyingEmail = false;
        // Old admin (already has a custom pin, not Hostel@123, not empty)
        if (_matchedAdmin!.pin.isNotEmpty && _matchedAdmin!.pin != 'Hostel@123' && _matchedAdmin!.pin != hashPassword('Hostel@123')) {
           _authStage = AuthStage.personalPassword;
        } else {
           // New admin
           _authStage = AuthStage.standardPassword;
        }
        adminPhotoUrl = _matchedAdmin!.photoUrl;
      });
      return;
    }

    // Student Check (Email)
    _isAdminFlow = false;
    String email = input.toLowerCase();
    if (!email.contains('@')) {
      setState(() => _isVerifyingEmail = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Email format')));
      return;
    }
    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData_${globalHostelMode}/students').get();
      if (snap.exists && snap.value != null) {
        globalRegisteredStudents.clear();
        for(var s in (snap.value as List)) {
          if (s != null) {
            var st = RegisteredStudent.fromJson(Map<String,dynamic>.from(s));
            if (st.isValid) globalRegisteredStudents.add(st);
          }
        }
      }
    } catch(e) {}
    
    _matchedStudent = null;
    for (var s in globalRegisteredStudents) {
      if (s.email.toLowerCase() == email) {
        _matchedStudent = s;
        break;
      }
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
        await _sendFirebaseAdminOtp();
      } else if (_authStage == AuthStage.personalPassword) {
        String hashed = hashPassword(typedPin);
        if (_matchedAdmin!.pin == typedPin || _matchedAdmin!.pin == hashed) {
          await _sendFirebaseAdminOtp(); // Send OTP even for old admin
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Password!')));
        }
      } else if (_authStage == AuthStage.newPassword) {
         if (typedPin.length != 8 || typedPin != _studentRePinController.text) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords must be 8 chars and match!')));
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
      } else if (_authStage == AuthStage.otp) {
         await _verifyFirebaseAdminOtp(typedPin);
      }
      return;
    }
    
    // Student logic
    if (typedPin.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be 8 characters.')));
      return;
    }
    
    if (_authStage == AuthStage.newPassword) {
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
  
  Future<void> _sendFirebaseAdminOtp() async {
     setState(() => _isVerifyingEmail = true);
     try {
       await FirebaseAuth.instance.verifyPhoneNumber(
         phoneNumber: "+91${_matchedAdmin!.phone}",
         verificationCompleted: (PhoneAuthCredential credential) async {
             // Auto-resolve
             setState(() => _isVerifyingEmail = false);
         },
         verificationFailed: (FirebaseAuthException e) {
             setState(() => _isVerifyingEmail = false);
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SMS Failed: ${e.message}')));
         },
         codeSent: (String verificationId, int? resendToken) {
             setState(() {
                _isVerifyingEmail = false;
                _adminVerificationId = verificationId;
                _authStage = AuthStage.otp;
                _studentPinController.clear();
             });
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS OTP Sent!')));
         },
         codeAutoRetrievalTimeout: (String verificationId) {
             _adminVerificationId = verificationId;
         },
       );
     } catch (e) {
         setState(() => _isVerifyingEmail = false);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS Error. Did you add SHA-1 to Firebase?')));
     }
  }
  
  Future<void> _verifyFirebaseAdminOtp(String otp) async {
     setState(() => _isVerifyingEmail = true);
     try {
       PhoneAuthCredential credential = PhoneAuthProvider.credential(
         verificationId: _adminVerificationId,
         smsCode: otp,
       );
       await FirebaseAuth.instance.signInWithCredential(credential);
       setState(() => _isVerifyingEmail = false);
       
       // Success!
       if (_matchedAdmin!.pin.isNotEmpty && _matchedAdmin!.pin != 'Hostel@123' && _matchedAdmin!.pin != hashPassword('Hostel@123')) {
          // Old Admin
          await _finalizeAdminLogin(_matchedAdmin!);
       } else {
          // New Admin
          setState(() {
             _authStage = AuthStage.newPassword;
             _studentPinController.clear();
          });
       }
     } catch(e) {
       setState(() => _isVerifyingEmail = false);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
     }
  }

  Future<void> _finalizeAdminLogin(AdminUser admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_admin_phone', admin.phone);
    await prefs.setString('last_admin_name', admin.name);
    await prefs.setString('last_admin_photo', admin.photoUrl ?? '');
    await prefs.setString('userType', 'admin');
    await prefs.setString('identifier', admin.phone);
    await prefs.setString('photoPath', admin.photoUrl ?? '');
    await prefs.setString('extraInfo', admin.name);
    await NotificationService.saveToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDashboardScreen(
          photoUrl: admin.photoUrl,
          name: admin.name,
          phone: admin.phone,
        ),
      ),
    );
  }
"""

# Replace old methods with new unified logic
start_idx = text.find("  Widget _buildStudentPortal() {")
if start_idx != -1:
    text = text[:start_idx] + unified_logic + "\n\n" + text[start_idx:]

# Now replace the StudentPortal UI to be the Unified UI
ui_replacement = """Widget _buildStudentPortal() {
    return Container(
      key: const ValueKey("StudentPortal"),
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
                Icon(Icons.login, color: brandOrange, size: 22),
                SizedBox(width: 10),
                Text(
                  "Login",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // STAGE: IDENTIFIER
            if (_authStage == AuthStage.identifier && !hasSavedStudent && !hasSavedAdmin) ...[
              const Text("Registered Email", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter your registered email",
                  prefixIcon: const Icon(Icons.email_outlined, color: brandGray, size: 20),
                  filled: true,
                  fillColor: brandInputBg,
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
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isVerifyingEmail 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Next", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],

            // STAGE: PASSWORD / OTP / SETUP
            if (_authStage != AuthStage.identifier || hasSavedStudent || hasSavedAdmin) ...[
              Center(
                child: Column(
                  children: [
                    if (_authStage == AuthStage.newPassword) ...[
                      GestureDetector(
                        onTap: () => _pickImage(true), // true uses studentPhotoUrl which we aliased for admin too
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE9D2),
                                shape: BoxShape.circle,
                                image: (studentPhotoUrl != null && studentPhotoUrl!.isNotEmpty) 
                                  ? DecorationImage(image: NetworkImage(studentPhotoUrl!), fit: BoxFit.cover) : null,
                              ),
                              child: (studentPhotoUrl == null || studentPhotoUrl!.isEmpty)
                                  ? const Icon(Icons.camera_alt_outlined, color: brandOrange, size: 38) : null,
                            ),
                            Positioned(
                              bottom: 2, right: 2,
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: brandOrange, shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3.0),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text("Upload Photo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: brandGray)),
                    ] else ...[
                      // Logged in or returning user photo
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: brandInputBg,
                          image: (studentPhotoUrl != null && studentPhotoUrl!.isNotEmpty) 
                            ? DecorationImage(image: NetworkImage(studentPhotoUrl!), fit: BoxFit.cover) : null,
                        ),
                        child: (studentPhotoUrl == null || studentPhotoUrl!.isEmpty)
                            ? const Icon(Icons.person, color: brandGray, size: 32) : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      _isAdminFlow ? (_matchedAdmin?.name ?? "Admin") : (_matchedStudent?.name ?? selectedStudentName ?? "Student"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_authStage == AuthStage.otp) ...[
                 const Text("Enter SMS OTP", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
              ] else ...[
                 const Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
              ],
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentPinController,
                obscureText: (_authStage != AuthStage.otp) && !isStudentPinVisible,
                keyboardType: _authStage == AuthStage.otp ? TextInputType.number : TextInputType.text,
                maxLength: _authStage == AuthStage.otp ? 6 : (_authStage == AuthStage.standardPassword ? null : 8),
                decoration: InputDecoration(
                  hintText: _authStage == AuthStage.otp ? "6-digit OTP" : (_authStage == AuthStage.newPassword ? "Create 8-char password" : "Enter password"),
                  prefixIcon: Icon(_authStage == AuthStage.otp ? Icons.message : Icons.lock_outline, color: brandGray, size: 20),
                  suffixIcon: _authStage == AuthStage.otp ? null : IconButton(
                    icon: Icon(isStudentPinVisible ? Icons.visibility : Icons.visibility_off, color: brandGray, size: 20),
                    onPressed: () => setState(() => isStudentPinVisible = !isStudentPinVisible),
                  ),
                  filled: true,
                  fillColor: brandInputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              
              if (_authStage == AuthStage.newPassword) ...[
                const SizedBox(height: 16),
                const Text("Confirm Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _studentRePinController,
                  obscureText: !isStudentRePinVisible,
                  maxLength: 8,
                  decoration: InputDecoration(
                    hintText: "Re-enter password",
                    prefixIcon: const Icon(Icons.lock_outline, color: brandGray, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(isStudentRePinVisible ? Icons.visibility : Icons.visibility_off, color: brandGray, size: 20),
                      onPressed: () => setState(() => isStudentRePinVisible = !isStudentRePinVisible),
                    ),
                    filled: true,
                    fillColor: brandInputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifyingEmail ? null : _handleUnifiedAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isVerifyingEmail 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                      _authStage == AuthStage.newPassword ? "Complete Registration" : (_authStage == AuthStage.otp ? "Verify OTP" : "Login"),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () async {
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
                      studentPhotoUrl = null;
                      adminPhotoUrl = null;
                    });
                  },
                  child: const Text("Not you? Go back", style: TextStyle(color: brandGray, decoration: TextDecoration.underline)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }"""

start_idx2 = text.find("Widget _buildStudentPortal() {")
end_idx2 = text.find("Widget _buildAdminPortal() {", start_idx2)

if start_idx2 != -1 and end_idx2 != -1:
    text = text[:start_idx2] + ui_replacement + "\n\n  " + text[end_idx2:]

# Also, in the build method, we only show _buildStudentPortal() which acts as unified, and hide admin toggle!
# Let's find the toggle code.
toggle_start = text.find("if (_pageState != 0 && !hasSavedStudent && !hasSavedAdmin)")
toggle_end = text.find("// Form", toggle_start)
if toggle_start != -1 and toggle_end != -1:
    text = text[:toggle_start] + text[toggle_end:]

# Replace AnimatedSwitcher condition
text = text.replace("child: isStudent ? _buildStudentPortal() : _buildAdminPortal(),", "child: _buildStudentPortal(),")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Applied unified login patch successfully!")
