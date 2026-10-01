import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Update Student Password UI to include Forgot Password
student_pwd = '''              _buildPasswordField(
                controller: _studentPinController,
                label: "8 Character Password",
                hintText: "Enter 8-character Password",
                icon: Icons.dialpad,
                isStudent: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    8,
                  ), // strictly limits to 8 characters
                ],
              ),'''

student_pwd_new = '''              _buildPasswordField(
                controller: _studentPinController,
                label: "8 Character Password",
                hintText: "Enter 8-character Password",
                icon: Icons.dialpad,
                isStudent: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(8),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _handleForgotPassword(true),
                  child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                ),
              ),'''
code = code.replace(student_pwd, student_pwd_new)

# 2. Update Admin Password UI to include Forgot Password
admin_pwd = '''              _buildPasswordField(
                controller: _adminPasswordController,
                label: "Secure Password",
                hintText: "Enter your password",
                icon: Icons.lock_outline,
                isStudent: false,
              ),'''

admin_pwd_new = '''              _buildPasswordField(
                controller: _adminPasswordController,
                label: "Secure Password",
                hintText: "Enter your password",
                icon: Icons.lock_outline,
                isStudent: false,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _handleForgotPassword(false),
                  child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                ),
              ),'''
code = code.replace(admin_pwd, admin_pwd_new)

# 3. Add 'Not you? Logout' buttons if hasSavedStudent / hasSavedAdmin
student_title = '''              const Row(
                children: [
                  Icon(Icons.restaurant, color: brandOrange, size: 22),
                  SizedBox(width: 10),
                  Text(
                    "Student Portal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: brandDark,
                    ),
                  ),
                ],
              ),'''
student_title_new = '''              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.restaurant, color: brandOrange, size: 22),
                      SizedBox(width: 10),
                      Text("Student Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark)),
                    ],
                  ),
                  if (hasSavedStudent)
                    TextButton(
                      onPressed: _clearSavedStudent,
                      child: const Text("Not you?", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    )
                ],
              ),'''
code = code.replace(student_title, student_title_new)

admin_title = '''              const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: brandOrange, size: 22),
                  SizedBox(width: 10),
                  Text(
                    "Admin Portal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: brandDark,
                    ),
                  ),
                ],
              ),'''
admin_title_new = '''              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.admin_panel_settings, color: brandOrange, size: 22),
                      SizedBox(width: 10),
                      Text("Admin Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark)),
                    ],
                  ),
                  if (hasSavedAdmin)
                    TextButton(
                      onPressed: _clearSavedAdmin,
                      child: const Text("Not you?", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    )
                ],
              ),'''
code = code.replace(admin_title, admin_title_new)

# 4. Save student credentials correctly
student_save_old = """    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userType', 'student');"""
student_save_new = """    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_student_name', typedName);
    await prefs.setString('last_student_room', selectedRoom!);
    await prefs.setString('last_student_photo', studentPhotoUrl ?? '');
    await prefs.setString('userType', 'student');"""
code = code.replace(student_save_old, student_save_new)

admin_save_old = """          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', 'admin');"""
admin_save_new = """          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_admin_phone', admin.phone);
          await prefs.setString('last_admin_name', _adminNameController.text);
          await prefs.setString('last_admin_photo', adminPhotoUrl ?? '');
          await prefs.setString('userType', 'admin');"""
code = code.replace(admin_save_old, admin_save_new)

# 5. Fix _handleForgotPassword variables
forgot_old = """    Future<void> _handleForgotPassword(bool isStudentReq) async {
      String? emailToSend;
      if (isStudentReq) {
        if (savedStudentName == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No saved student found.")));
          return;
        }
        var match = globalRegisteredStudents.where((s) => s.name == savedStudentName);"""
forgot_new = """    Future<void> _handleForgotPassword(bool isStudentReq) async {
      String? emailToSend;
      String? targetIdentifier;
      if (isStudentReq) {
        targetIdentifier = selectedStudentName;
        if (targetIdentifier == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your name first.")));
          return;
        }
        var match = globalRegisteredStudents.where((s) => s.name == targetIdentifier);"""
code = code.replace(forgot_old, forgot_new)

forgot_admin_old = """      } else {
        if (savedAdminPhone == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No saved admin found.")));
          return;
        }
        var match = globalAdmins.where((a) => a.phone == savedAdminPhone);"""
forgot_admin_new = """      } else {
        targetIdentifier = _adminMobileController.text.trim();
        if (targetIdentifier.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your mobile number first.")));
          return;
        }
        var match = globalAdmins.where((a) => a.phone == targetIdentifier);"""
code = code.replace(forgot_admin_old, forgot_admin_new)

forgot_reset_old = """                if (newPassCtrl.text == rePassCtrl.text && newPassCtrl.text.length >= 8) {
                  if (isStudentReq) {
                    var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name == savedStudentName);
                    existingStudent.pin = newPassCtrl.text;
                    SyncService.pushStudents();
                  } else {
                    var admin = globalAdmins.firstWhere((a) => a.phone == savedAdminPhone);
                    admin.pin = newPassCtrl.text;
                    SyncService.pushAdmins();
                  }"""
forgot_reset_new = """                if (newPassCtrl.text == rePassCtrl.text && newPassCtrl.text.length >= 8) {
                  if (isStudentReq) {
                    var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name == targetIdentifier);
                    existingStudent.pin = hashPassword(newPassCtrl.text);
                    SyncService.pushStudents();
                  } else {
                    var admin = globalAdmins.firstWhere((a) => a.phone == targetIdentifier);
                    admin.pin = hashPassword(newPassCtrl.text);
                    SyncService.pushAdmins();
                  }"""
code = code.replace(forgot_reset_old, forgot_reset_new)

# 6. Display Breakfast/Lunch/Dinner Text in ViewMenuTab
view_menu_old = """    if (globalMenuFile == null && globalMenuUploadBytes == null && globalMenuUrl == null) {
      return const Center(
        child: Text("No menu uploaded yet.", style: TextStyle(color: brandGray)),
      );
    }"""
view_menu_new = """
    String todayStr = "--";
    final defaultMenu = defaultWeeklyMenu[DateTime.now().weekday] ?? defaultWeeklyMenu[DateTime.monday]!;
    
    // We will build a text summary to show above the menu image
    Widget menuTextSection = FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance.ref('hostelData/daily_menus/').get(),
      builder: (context, snapshot) {
        String bf = defaultMenu['breakfast']!;
        String lu = defaultMenu['lunch']!;
        String dn = defaultMenu['dinner']!;
        if (snapshot.hasData && snapshot.data!.value != null) {
          final data = Map<String, dynamic>.from(snapshot.data!.value as Map);
          bf = data['breakfast'] ?? bf;
          lu = data['lunch'] ?? lu;
          dn = data['dinner'] ?? dn;
        }
        
        String formattedDate = " ,  - ";
        
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandOrange)),
              const Divider(),
              Text("?? Breakfast: ", style: const TextStyle(fontSize: 15, height: 1.5, color: brandDark)),
              Text("?? Lunch: ", style: const TextStyle(fontSize: 15, height: 1.5, color: brandDark)),
              Text("?? Dinner: ", style: const TextStyle(fontSize: 15, height: 1.5, color: brandDark)),
            ],
          ),
        );
      }
    );

    if (globalMenuFile == null && globalMenuUploadBytes == null && globalMenuUrl == null) {
      return Column(
        children: [
          menuTextSection,
          const Expanded(child: Center(child: Text("No menu image uploaded yet.", style: TextStyle(color: brandGray)))),
        ],
      );
    }
"""

view_menu_pdf_old = """    if (globalMenuIsPdf) {
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
    return const Center(child: Icon(Icons.image, size: 50));"""

view_menu_pdf_new = """    Widget mediaViewer;
    if (globalMenuIsPdf) {
      if (globalMenuUploadBytes != null) {
        mediaViewer = SfPdfViewer.memory(globalMenuUploadBytes!);
      } else if (globalMenuUrl != null && globalMenuUrl!.isNotEmpty && globalMenuUrl!.startsWith('http')) {
        mediaViewer = SfPdfViewer.network(globalMenuUrl!);
      } else if (globalMenuFile != null) {
        mediaViewer = SfPdfViewer.file(globalMenuFile!);
      } else {
        mediaViewer = const Center(child: Text("PDF Error"));
      }
    } else {
      if (globalMenuUploadBytes != null) {
        mediaViewer = InteractiveViewer(child: Center(child: Image.memory(globalMenuUploadBytes!)));
      } else if (globalMenuUrl != null && globalMenuUrl!.isNotEmpty && globalMenuUrl!.startsWith('http')) {
        mediaViewer = InteractiveViewer(child: Center(child: Image.network(globalMenuUrl!)));
      } else if (globalMenuFile != null && !kIsWeb) {
        mediaViewer = InteractiveViewer(child: Center(child: Image.file(globalMenuFile!)));
      } else {
        mediaViewer = const Center(child: Icon(Icons.image, size: 50));
      }
    }
    
    return Column(
      children: [
        menuTextSection,
        Expanded(child: mediaViewer),
      ],
    );"""

code = code.replace(view_menu_old, view_menu_new)
code = code.replace(view_menu_pdf_old, view_menu_pdf_new)

# Add helpers for ViewMenuTab if they don't exist
helpers = """
String _getMonthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
}

String _getWeekdayName(int weekday) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return days[weekday - 1];
}
"""
code = code.replace("class ViewMenuTab extends StatelessWidget {", helpers + "\nclass ViewMenuTab extends StatelessWidget {")


# 7. About Developers Screen Responsive UI
dev_old = """        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              // Logo Section"""
dev_new = """        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  const Text("MDHK TENSORS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2.0)),
                  const SizedBox(height: 20),
                  // Logo Section"""
code = code.replace(dev_old, dev_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Applied 6-digit OTP UI hooks, Menu UI with Date/Day, and AboutDev fixes")
