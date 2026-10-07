import sys
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

start = text.find('    Widget _buildStudentPortal() {')
end = text.find('    Widget _buildAdminPortal() {', start)

if start != -1 and end != -1:
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
                Icon(Icons.login, color: brandOrange, size: 22),
                SizedBox(width: 10),
                Text(
                  "Login",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // === STAGE: IDENTIFIER (Email or Mobile) ===
            if (_authStage == AuthStage.identifier && !hasSavedStudent && !hasSavedAdmin) ...[
              const Text("Registered Email / Mobile", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter registered email or mobile number",
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

            // === STAGE: STANDARD PASSWORD (Admin only) ===
            if (_authStage == AuthStage.standardPassword) ...[
              const Center(child: Icon(Icons.admin_panel_settings, color: brandOrange, size: 48)),
              const SizedBox(height: 12),
              const Center(child: Text("Admin Verification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
              const SizedBox(height: 24),
              const Text("Standard Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentPinController,
                obscureText: !isStudentPinVisible,
                decoration: InputDecoration(
                  hintText: "Enter standard password",
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
              const SizedBox(height: 24),
              _buildActionButton("Verify", _handleUnifiedAction),
              const SizedBox(height: 12),
              _buildBackButton(),
            ],

            // === STAGE: ADMIN EMAIL (after standard password) ===
            if (_authStage == AuthStage.adminEmail) ...[
              const Center(child: Icon(Icons.email, color: brandOrange, size: 48)),
              const SizedBox(height: 12),
              const Center(child: Text("Email Verification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
              const SizedBox(height: 24),
              const Text("Your Registered Email", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _adminEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter your registered email",
                  prefixIcon: const Icon(Icons.email_outlined, color: brandGray, size: 20),
                  filled: true,
                  fillColor: brandInputBg,
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
                                color: brandLightOrange, shape: BoxShape.circle,
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
                                decoration: BoxDecoration(color: brandOrange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3.0)),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Upload Photo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: brandGray)),
                    ] else ...[
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: brandInputBg,
                          image: (() {
                            String? photo = _isAdminFlow ? adminPhotoUrl : (studentPhotoUrl ?? savedStudentPhoto);
                            return (photo != null && photo.isNotEmpty) ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover) : null;
                          })(),
                        ),
                        child: (() {
                          String? photo = _isAdminFlow ? adminPhotoUrl : (studentPhotoUrl ?? savedStudentPhoto);
                          return (photo == null || photo.isEmpty) ? const Icon(Icons.person, color: brandGray, size: 32) : null;
                        })(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_authStage == AuthStage.newPassword && !_isAdminFlow && _matchedStudent != null) ...[
                      Text(_matchedStudent!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
                      Text("Room: ", style: const TextStyle(fontSize: 14, color: brandGray)),
                    ] else if (_isAdminFlow || hasSavedAdmin) ...[
                      const Text("Admin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
                    ] else ...[
                      Text(
                        hasSavedStudent ? (savedStudentName ?? "Student") : (_matchedStudent?.name ?? selectedStudentName ?? "Student"),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentPinController,
                obscureText: !isStudentPinVisible,
                maxLength: 16,
                decoration: InputDecoration(
                  hintText: _authStage == AuthStage.newPassword ? "Create password (8-16 chars)" : "Enter password",
                  prefixIcon: const Icon(Icons.lock_outline, color: brandGray, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(isStudentPinVisible ? Icons.visibility : Icons.visibility_off, color: brandGray, size: 20),
                    onPressed: () => setState(() => isStudentPinVisible = !isStudentPinVisible),
                  ),
                  filled: true, fillColor: brandInputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  counterText: "",
                ),
              ),
              
              if (_authStage == AuthStage.newPassword) ...[
                const SizedBox(height: 6),
                _buildPasswordHints(_studentPinController.text),
                const SizedBox(height: 16),
                const Text("Confirm Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _studentRePinController,
                  obscureText: !isStudentRePinVisible,
                  maxLength: 16,
                  decoration: InputDecoration(
                    hintText: "Re-enter password",
                    prefixIcon: const Icon(Icons.lock_outline, color: brandGray, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(isStudentRePinVisible ? Icons.visibility : Icons.visibility_off, color: brandGray, size: 20),
                      onPressed: () => setState(() => isStudentRePinVisible = !isStudentRePinVisible),
                    ),
                    filled: true, fillColor: brandInputBg,
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
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.w500)),
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
          backgroundColor: brandOrange,
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
        child: const Text("← Go back to login / Switch user", style: TextStyle(color: brandGray, decoration: TextDecoration.underline)),
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
        Icon(ok ? Icons.check_circle : Icons.circle_outlined, size: 14, color: ok ? Colors.green : brandGray),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: ok ? Colors.green : brandGray)),
      ],
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hint("8-16 characters", hasLength),
        hint("At least 1 uppercase letter", hasUpper),
        hint("At least 1 number", hasNumber),
        hint("At least 1 special character (!@#\$%^&*)", hasSpecial),
      ],
    );
  }

\n  '''
    text = text[:start] + new_unified_portal + text[end:]
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS: Unified portal applied.")
else:
    print(f"FAILED: start={start}, end={end}")
