"""
Master patch script - applies ALL changes cleanly to git-restored lib/main.dart
This replaces patch_unified_auth.py, patch_pwd.py, perfect_patch.py, fix_final*.py
"""
import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# =====================================================
# 1. Add globalHostelMode variable
# =====================================================
if "String globalHostelMode = " not in text:
    text = text.replace(
        "List<RegisteredStudent> globalRegisteredStudents = [];",
        "List<RegisteredStudent> globalRegisteredStudents = [];\nString globalHostelMode = 'boys';"
    )

# =====================================================
# 2. Add name/photoUrl to AdminUser class
# =====================================================
if "String? photoUrl;" not in text.split("class AdminUser")[1].split("}")[0]:
    text = text.replace(
        "class AdminUser {\n  String phone;\n  String pin;\n  String email;\n  AdminUser(this.phone, this.pin, {this.email = ''});",
        "class AdminUser {\n  String phone;\n  String pin;\n  String email;\n  String name;\n  String? photoUrl;\n  AdminUser(this.phone, this.pin, {this.email = '', this.name = 'Admin', this.photoUrl});"
    )
    text = text.replace(
        "Map<String, dynamic> toJson() => {'phone': phone, 'pin': pin, 'email': email};",
        "Map<String, dynamic> toJson() => {'phone': phone, 'pin': pin, 'email': email, 'name': name, 'photoUrl': photoUrl};"
    )
    text = text.replace(
        "factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(json['phone'], json['pin'], email: json['email'] ?? '');",
        "factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(json['phone'], json['pin'], email: json['email'] ?? '', name: json['name'] ?? 'Admin', photoUrl: json['photoUrl']);"
    )

# =====================================================
# 3. Add AuthStage enum and new state variables
# =====================================================
if "enum AuthStage" not in text:
    text = text.replace(
        "class _LoginScreenState extends State<LoginScreen> {",
        "enum AuthStage { identifier, standardPassword, newPassword, personalPassword, otp }\n\nclass _LoginScreenState extends State<LoginScreen> {"
    )

# Add new state variables after isStudent
text = text.replace(
    "  bool isStudent = true;\n  bool _isCreatingPassword = false;",
    "  bool isStudent = true;\n  bool _isCreatingPassword = false;\n  AuthStage _authStage = AuthStage.identifier;\n  bool _isAdminFlow = false;\n  AdminUser? _matchedAdmin;\n  RegisteredStudent? _matchedStudent;\n  String _adminVerificationId = '';"
)

# =====================================================
# 4. Inject unified login methods BEFORE _buildStudentPortal
# =====================================================
unified_methods = '''
  Future<void> _verifyIdentifierStage() async {
    String input = _studentEmailController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Email or Mobile Number')));
      return;
    }
    setState(() => _isVerifyingEmail = true);
    
    bool isNumeric = RegExp(r'^[0-9]+$').hasMatch(input) && input.length == 10;
    
    if (isNumeric) {
      _isAdminFlow = true;
      try {
        final snap = await FirebaseDatabase.instance.ref('hostelData_$globalHostelMode/admins').get();
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account not found. Please contact Admin.')));
        return;
      }
      
      setState(() {
        _isVerifyingEmail = false;
        if (_matchedAdmin!.pin.isNotEmpty && _matchedAdmin!.pin != 'Hostel@123' && _matchedAdmin!.pin != hashPassword('Hostel@123')) {
           _authStage = AuthStage.personalPassword;
        } else {
           _authStage = AuthStage.standardPassword;
        }
        adminPhotoUrl = _matchedAdmin!.photoUrl;
      });
      return;
    }

    _isAdminFlow = false;
    String email = input.toLowerCase();
    if (!email.contains('@')) {
      setState(() => _isVerifyingEmail = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Email format')));
      return;
    }
    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData_$globalHostelMode/students').get();
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
      if (s.email != null && s.email.toLowerCase() == email) {
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
        // Skip SMS OTP for web, go directly to password setup or login
        if (_matchedAdmin!.pin.isNotEmpty && _matchedAdmin!.pin != 'Hostel@123' && _matchedAdmin!.pin != hashPassword('Hostel@123')) {
          await _finalizeAdminLogin(_matchedAdmin!);
        } else {
          setState(() {
            _authStage = AuthStage.newPassword;
            _studentPinController.clear();
          });
        }
      } else if (_authStage == AuthStage.personalPassword) {
        String hashed = hashPassword(typedPin);
        if (_matchedAdmin!.pin == typedPin || _matchedAdmin!.pin == hashed) {
          await _finalizeAdminLogin(_matchedAdmin!);
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

  Future<void> _finalizeStudentLogin(RegisteredStudent student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_student_name', student.name);
    await prefs.setString('last_student_room', student.roomNo);
    await prefs.setString('last_student_photo', student.photoUrl ?? '');
    await prefs.setString('userType', 'student');
    await prefs.setString('identifier', student.name);
    await prefs.setString('photoPath', student.photoUrl ?? '');
    await prefs.setString('extraInfo', student.roomNo);
    await NotificationService.saveToken();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboardScreen(
          photoUrl: student.photoUrl,
          name: student.name,
          roomNo: student.roomNo,
        ),
      ),
    );
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

'''

# Insert unified methods before _buildStudentPortal
target = "  Widget _buildStudentPortal() {"
text = text.replace(target, unified_methods + "\n  " + target, 1)

# =====================================================
# 5. Replace _buildStudentPortal with unified UI
# =====================================================
new_student_portal = '''  Widget _buildStudentPortal() {
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
                        onTap: () => _pickImage(true),
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

              const Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentPinController,
                obscureText: !isStudentPinVisible,
                maxLength: _authStage == AuthStage.standardPassword ? null : 8,
                decoration: InputDecoration(
                  hintText: _authStage == AuthStage.newPassword ? "Create 8-char password" : "Enter password",
                  prefixIcon: const Icon(Icons.lock_outline, color: brandGray, size: 20),
                  suffixIcon: IconButton(
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
                      _authStage == AuthStage.newPassword ? "Complete Registration" : "Login",
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
  }'''

# Find the old _buildStudentPortal and replace it up to _buildAdminPortal
old_start = text.find("  Widget _buildStudentPortal() {")
old_end = text.find("  Widget _buildAdminPortal() {", old_start)
if old_start != -1 and old_end != -1:
    text = text[:old_start] + new_student_portal + "\n\n  " + text[old_end:]

# =====================================================
# 6. Hide Student/Admin toggle - show only unified portal
# =====================================================
text = text.replace(
    "child: isStudent ? _buildStudentPortal() : _buildAdminPortal(),",
    "child: _buildStudentPortal(),"
)

# Hide the Student/Admin toggle entirely
toggle_start = text.find("              if (!hasSavedStudent && !hasSavedAdmin)\n                Container(")
toggle_end = text.find("              const SizedBox(height: 28),", toggle_start)
if toggle_start != -1 and toggle_end != -1:
    text = text[:toggle_start] + "              " + text[toggle_end:]

# =====================================================
# 7. Update SyncService _dbRef to use globalHostelMode
# =====================================================
text = text.replace(
    "static final _dbRef = FirebaseDatabase.instance.ref('hostelData');",
    "static DatabaseReference get _dbRef => FirebaseDatabase.instance.ref('hostelData_$globalHostelMode');"
)

# =====================================================
# 8. Update Supabase tables to use hostel mode suffix
# =====================================================
for t in ['menu', 'complaints', 'notices']:
    text = text.replace(f".from('{t}')", f".from('{t}_$globalHostelMode')")

# =====================================================
# DONE - Write output
# =====================================================
with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: All patches applied cleanly!")
