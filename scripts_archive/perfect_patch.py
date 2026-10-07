import re
import shutil

shutil.copy2("lib/main.dart.bak", "lib/main.dart")

with open("lib/main.dart", "r", encoding="utf-8") as f:
    code = f.read()

# 1. Global Hostel Mode
code = code.replace(
    "List<RegisteredStudent> globalRegisteredStudents = [];\n",
    "List<RegisteredStudent> globalRegisteredStudents = [];\nString globalHostelMode = 'boys';\n"
)

# 2. SyncService _dbRef
code = code.replace(
    "static final _dbRef = FirebaseDatabase.instance.ref('hostelData');\n  static bool _isSyncingIn = false;",
    "static DatabaseReference get _dbRef => FirebaseDatabase.instance.ref('hostelData_$globalHostelMode');\n  static StreamSubscription? _firebaseSubscription;\n  static bool _isSyncingIn = false;"
)

# 3. Supabase tables
tables = ['menu', 'complaints', 'notices']
for t in tables:
    code = code.replace(f".from('{t}')", f".from('{t}_$globalHostelMode')")

# 4. SyncService listen / switchMode
code = code.replace(
    "static void listen() {\n    initSupabaseStreams();\n    _dbRef.onValue.listen",
    "static void listen() {\n    initSupabaseStreams();\n    _firebaseSubscription?.cancel();\n    _firebaseSubscription = _dbRef.onValue.listen"
)

switch_code = """
  static void switchMode(String newMode) {
    if (globalHostelMode == newMode) return;
    globalHostelMode = newMode;
    listen();
  }
"""
code = code.replace("static void listen() {", switch_code + "  static void listen() {")

# --- UI Methods Patches ---

# Replace `_buildStudentPortal`
def replace_method(source, start_marker, end_marker, replacement):
    start = source.find(start_marker)
    if start == -1: raise Exception(f"Start marker not found: {start_marker}")
    end = source.find(end_marker, start)
    if end == -1: raise Exception(f"End marker not found: {end_marker}")
    return source[:start] + replacement + "\n\n" + source[end:]

p_sel = """  Widget _buildSelectionScreen() {
    return Column(
      key: const ValueKey(0),
      children: [
        const SizedBox(height: 20),
        _buildSelectionCard("≡ƒæ¿ Boys Hostel", "Join the Boys Hostel Mess", () {
          SyncService.switchMode("boys");
          setState(() { _pageState = 1; isStudent = true; });
        }),
        const SizedBox(height: 20),
        _buildSelectionCard("≡ƒæ⌐ Girls Hostel", "Join the Girls Hostel Mess", () {
          SyncService.switchMode("girls");
          setState(() { _pageState = 1; isStudent = true; });
        }),
        const SizedBox(height: 40),
        TextButton.icon(
          onPressed: () {
            setState(() { _pageState = 2; isStudent = false; });
          },
          icon: const Icon(Icons.security, color: Color(0xFF9E9E9E), size: 18),
          label: const Text("Admin Login", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildSelectionCard(String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.apartment, color: Color(0xFFF57C00), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF718096))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFFCBD5E0), size: 16),
          ],
        ),
      ),
    );
  }"""

p_stu = """  Widget _buildStudentPortal() {
    String? finalEmail;

    if (isStudentForm) {
      if (_emailChecked && selectedStudentName != null && selectedRoom != null) {
        try {
          var existing = globalRegisteredStudents.firstWhere((s) => s.roomNo == selectedRoom && s.name == selectedStudentName);
          finalEmail = existing.email;
        } catch (e) {
          finalEmail = _studentEmailController.text.trim();
        }
      } else {
        finalEmail = _studentEmailController.text.trim();
      }
    } else {
      finalEmail = _adminEmailController.text.trim();
    }
    return Container(
      key: const ValueKey("StudentPortalNew"),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Form(
        key: _studentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, color: brandOrange, size: 22),
                SizedBox(width: 10),
                Text("Student Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark)),
              ],
            ),
            const SizedBox(height: 28),
            
            if (!_emailChecked) ...[
              _buildInputField(label: "Email Address", hintText: "Enter your email", controller: _studentEmailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 24),
              _buildPrimaryButton("Next", _checkStudentEmail),
            ] else ...[
              // Email is checked. Show appropriate flow based on whether they have a PIN
              Row(
                children: [
                  Expanded(child: Text(_studentEmailController.text, style: const TextStyle(fontWeight: FontWeight.w600, color: brandDark, fontSize: 15))),
                  IconButton(icon: const Icon(Icons.edit, color: brandGray, size: 18), onPressed: () => setState(() => _emailChecked = false)),
                ],
              ),
              const SizedBox(height: 20),
              
              if (_isCreatingPassword) ...[
                // New User Flow
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE9D2), shape: BoxShape.circle,
                          image: (studentPhotoUrl != null && studentPhotoUrl!.isNotEmpty) ? DecorationImage(image: NetworkImage(studentPhotoUrl!), fit: BoxFit.cover) : null,
                        ),
                        child: (studentPhotoUrl == null || studentPhotoUrl!.isEmpty) ? const Icon(Icons.camera_alt_outlined, color: brandOrange, size: 38) : null,
                      ),
                      Positioned(
                        bottom: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => _pickImage(true),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: brandOrange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Center(child: Text("Upload Photo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark))),
                const SizedBox(height: 24),
                Center(child: Text("Welcome, ${selectedStudentName ?? ''}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
                Center(child: Text("Room: ${selectedRoom ?? ''}", style: const TextStyle(fontSize: 14, color: brandGray))),
                const SizedBox(height: 24),
                _buildPasswordField(label: "Create 8-Digit PIN", hintText: "Enter 8 digits", icon: Icons.lock_outline, isStudent: true, controller: _studentPinController),
                const SizedBox(height: 16),
                _buildPasswordField(label: "Confirm PIN", hintText: "Enter 8 digits", icon: Icons.lock_outline, isStudent: true, controller: _studentRePinController),
                const SizedBox(height: 24),
                _buildPrimaryButton("Complete Setup & Login", _handleStudentLogin),
              ] else ...[
                // Existing User Flow
                Center(child: Text("Welcome back, ${selectedStudentName ?? ''}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark))),
                const SizedBox(height: 24),
                _buildPasswordField(label: "Enter PIN Password", hintText: "Enter 8 digits", icon: Icons.lock_outline, isStudent: true, controller: _studentPinController),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () {}, child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.w600))),
                ),
                const SizedBox(height: 24),
                _buildPrimaryButton("Login", _handleStudentLogin),
              ],
            ],
          ],
        ),
      ),
    );
  }"""

p_adm = """  Widget _buildAdminPortal() {
    return Container(
      key: const ValueKey("AdminPortalNew"),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Form(
        key: _adminFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: brandOrange, size: 22),
                SizedBox(width: 10),
                Text("Admin Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark)),
              ],
            ),
            const SizedBox(height: 28),
            
            _buildInputField(label: "Mobile Number", hintText: "Enter 10-digit number", controller: _adminMobileController, icon: Icons.phone_android, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildPasswordField(label: "Enter Admin PIN", hintText: "Enter your PIN", icon: Icons.lock_outline, isStudent: false, controller: _adminPassController),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () {}, child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.w600))),
            ),
            const SizedBox(height: 24),
            _buildPrimaryButton("Login", _handleAdminLogin),
          ],
        ),
      ),
    );
  }"""

p_drw = """            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [brandOrange, Color(0xFFF57C00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              accountName: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      globalHostelMode == 'boys' ? '≡ƒæ¿ Boys Hostel' : '≡ƒæ⌐ Girls Hostel',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: globalHostelMode == 'girls',
                    activeColor: Colors.white,
                    activeTrackColor: Colors.pinkAccent.withOpacity(0.5),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.blueAccent.withOpacity(0.5),
                    onChanged: (val) {
                      SyncService.switchMode(val ? 'girls' : 'boys');
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Switched to ${val ? 'Girls' : 'Boys'} Hostel')));
                    },
                  ),
                ],
              ),
              currentAccountPicture: Hero(
                tag: 'admin_avatar',
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: widget.photo != null ? MemoryImage(widget.photo!) : null,
                  child: widget.photo == null ? const Icon(Icons.person, color: brandOrange, size: 36) : null,
                ),
              ),
            ),"""

# Insert _buildSelectionScreen BEFORE _buildStudentPortal
idx = code.find("  Widget _buildStudentPortal() {")
code = code[:idx] + p_sel + "\n\n" + code[idx:]

# Replace _buildStudentPortal
code = replace_method(code, "  Widget _buildStudentPortal() {", "  Widget _buildAdminPortal() {", p_stu)

# Replace _buildAdminPortal
code = replace_method(code, "  Widget _buildAdminPortal() {", "  Widget _buildDropdownField() {", p_adm)

# Replace the Login tab view
old_tabs = """              if (!hasSavedStudent && !hasSavedAdmin)
                Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: brandInputBg,"""
end_tabs = """                child: isStudent ? _buildStudentPortal() : _buildAdminPortal(),
              ),"""
new_tabs = """              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeInQuart,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _pageState == 0 
                    ? _buildSelectionScreen() 
                    : (_pageState == 1 ? _buildStudentPortal() : _buildAdminPortal()),
              ),"""
start = code.find(old_tabs)
end = code.find(end_tabs, start)
if start != -1 and end != -1:
    code = code[:start] + new_tabs + code[end + len(end_tabs):]

# Replace _handleAdminLogin
code = replace_method(code, "  void _handleAdminLogin() {", "  @override\n  Widget build(BuildContext context) {", """  void _handleAdminLogin() async {
    String typedPass = _adminPassController.text.trim();
    String typedPhone = _adminMobileController.text.trim();
    if (typedPass.isEmpty || typedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Mobile and Password'), backgroundColor: Colors.redAccent));
      return;
    }

    AdminUser? foundAdmin;
    try {
      foundAdmin = globalAdmins.firstWhere((a) => a.phone == typedPhone && a.pin == hashPassword(typedPass));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Mobile Number or Password'), backgroundColor: Colors.redAccent));
      return;
    }

    if (foundAdmin.email.isEmpty) {
      // Need email setup (first time)
      String typedEmail = _adminEmailController.text.trim();
      if (typedEmail.isEmpty || !typedEmail.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email for first-time verification'), backgroundColor: Colors.redAccent));
        return;
      }
      
      setState(() => isVerifyingAdminOtp = true);
      String genOtp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      await EmailOtpService.sendOtp(typedEmail, genOtp);
      setState(() => isVerifyingAdminOtp = false);
      
      String? enteredOtp = await _showOtpDialog(typedEmail);
      if (enteredOtp == genOtp) {
        foundAdmin.email = typedEmail;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('globalAdmins', globalAdmins.map((a) => json.encode(a.toJson())).toList());
        await SyncService.pushAdmins();
        
        await _saveAdminLoginAndNavigate(typedPhone, foundAdmin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP'), backgroundColor: Colors.redAccent));
      }
    } else {
      // Direct login
      await _saveAdminLoginAndNavigate(typedPhone, foundAdmin);
    }
  }

  Future<void> _saveAdminLoginAndNavigate(String phone, AdminUser admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userType', 'admin');
    await prefs.setString('identifier', _adminNameController.text.trim());
    await prefs.setString('photoPath', '');
    await prefs.setString('extraInfo', phone);
    await NotificationService.saveToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDashboardScreen(
          photo: adminPhoto ?? Uint8List(0),
          name: _adminNameController.text.trim(),
        ),
      ),
    );
  }""")

# Drawer Header
d1 = code.find("            UserAccountsDrawerHeader(")
d2 = code.find("            ExpansionTile(", d1)
if d1 == -1 or d2 == -1: d2 = code.find("            ListTile(", d1)
if d1 != -1 and d2 != -1:
    code = code[:d1] + p_drw + "\n" + code[d2:]

# Quick fix for confirm pin toggle logic to _buildPasswordField
code = code.replace(
    "bool isVisible = isStudent ? isStudentPinVisible : isAdminPassVisible;",
    "bool isVisible = isStudent ? (label.contains('Confirm') ? isStudentRePinVisible : isStudentPinVisible) : isAdminPassVisible;"
)
code = code.replace(
    """              onPressed: () => setState(() {
                if (isStudent) {
                  isStudentPinVisible = !isStudentPinVisible;
                } else {
                  isAdminPassVisible = !isAdminPassVisible;
                }
              }),""",
    """              onPressed: () => setState(() {
                if (isStudent) {
                  if (label.contains('Confirm')) {
                    isStudentRePinVisible = !isStudentRePinVisible;
                  } else {
                    isStudentPinVisible = !isStudentPinVisible;
                  }
                } else {
                  isAdminPassVisible = !isAdminPassVisible;
                }
              }),"""
)

# Convert old widgets to new parameter names for compatibility
code = code.replace(
    '_buildTextField("Email Address", _studentEmailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress)',
    '_buildInputField(label: "Email Address", hintText: "Enter your email", controller: _studentEmailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress)'
)
code = code.replace(
    '_buildPinField("Create 8-Digit PIN", _studentPinController, isStudentPinVisible, () => setState(() => isStudentPinVisible = !isStudentPinVisible))',
    '_buildPasswordField(label: "Create 8-Digit PIN", hintText: "Enter 8 digits", icon: Icons.lock_outline, isStudent: true, controller: _studentPinController)'
)

# Replace _LoginScreenState variables
login_state_decl = """class _LoginScreenState extends State<LoginScreen> {
  int _pageState = 0; // 0: Selection, 1: Student, 2: Admin
  bool _emailChecked = false;
  bool _isCreatingPassword = false;
  final TextEditingController _studentEmailController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _studentPinController = TextEditingController();
  final TextEditingController _studentRePinController = TextEditingController();
  final TextEditingController _adminPassController = TextEditingController();
  bool isStudentPinVisible = false;
  bool isStudentRePinVisible = false;
  bool isAdminPassVisible = false;
  bool isVerifyingAdminOtp = false;

  RegisteredStudent? _matchedStudent;

  void _checkStudentEmail() async {
    String email = _studentEmailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
      return;
    }
    try {
      _matchedStudent = globalRegisteredStudents.firstWhere((s) => s.email.toLowerCase() == email);
      setState(() {
        selectedStudentName = _matchedStudent!.name;
        selectedRoom = _matchedStudent!.roomNo;
        studentPhotoUrl = _matchedStudent!.photoUrl;
        _isCreatingPassword = _matchedStudent!.pin.isEmpty;
        _emailChecked = true;
      });
    } catch(e) {
      String genOtp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      await EmailOtpService.sendOtp(email, genOtp);
      String? enteredOtp = await _showOtpDialog(email);
      if (enteredOtp == genOtp) {
         setState(() {
           _isCreatingPassword = true;
           _emailChecked = true;
         });
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
      }
    }
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF57C00),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }
"""
code = code.replace("class _LoginScreenState extends State<LoginScreen> {", login_state_decl)

# Fix saved logic states
c1 = code.find("        setState(() {")
c2 = code.find("      } else {", c1)
if c1 != -1 and c2 != -1 and code.find("_pageState", c1, c2) == -1:
    code = code[:c1] + """        setState(() {
          _pageState = 1;
        });\n""" + code[c2:]

c3 = code.find("      } else if (hasSavedAdmin) {")
c4 = code.find("      } else {", c3)
if c3 != -1 and c4 != -1 and code.find("_pageState", c3, c4) == -1:
    code = code[:c3] + """      } else if (hasSavedAdmin) {
        setState(() {
          _pageState = 2;
        });\n""" + code[c4:]

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(code)
print("Patcher 2.0 Complete!")
