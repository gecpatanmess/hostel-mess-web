with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old_str = """                      child: TextFormField(
                        controller: _otpControllers[i],
                        focusNode: _otpFocusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: _otpSent && !_isVerifying,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],"""

new_str = """                      child: TextFormField(
                        controller: _otpControllers[i],
                        focusNode: _otpFocusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: _otpSent && !_isVerifying,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onFieldSubmitted: (_) => _verifyOtp(),"""

code = code.replace(old_str, new_str)

# Also add to the email and password text fields in the main login UI!
# Let's find _studentEmailController and _studentPinController
email_old = """                TextFormField(
                  controller: _studentEmailController,
                  keyboardType: TextInputType.emailAddress,"""
email_new = """                TextFormField(
                  controller: _studentEmailController,
                  keyboardType: TextInputType.emailAddress,
                  onFieldSubmitted: (_) => _isVerifyingEmail ? null : _verifyIdentifierStage(),"""

pin_old = """                TextFormField(
                  controller: _studentPinController,
                  obscureText: !isStudentPinVisible,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration("""
pin_new = """                TextFormField(
                  controller: _studentPinController,
                  obscureText: !isStudentPinVisible,
                  onChanged: (val) => setState(() {}),
                  onFieldSubmitted: (_) => _handleUnifiedAction(),
                  decoration: InputDecoration("""

pin2_old = """                TextFormField(
                  controller: _studentPinController,
                  obscureText: !isStudentPinVisible,
                  onChanged: (val) => setState(() {}),
                  maxLength: 16,
                  decoration: InputDecoration("""
pin2_new = """                TextFormField(
                  controller: _studentPinController,
                  obscureText: !isStudentPinVisible,
                  onChanged: (val) => setState(() {}),
                  maxLength: 16,
                  onFieldSubmitted: (_) => _handleUnifiedAction(),
                  decoration: InputDecoration("""

admin_email_old = """                TextFormField(
                  controller: _adminEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration("""
admin_email_new = """                TextFormField(
                  controller: _adminEmailController,
                  keyboardType: TextInputType.emailAddress,
                  onFieldSubmitted: (_) => _handleUnifiedAction(),
                  decoration: InputDecoration("""

code = code.replace(email_old, email_new)
code = code.replace(pin_old, pin_new)
code = code.replace(pin2_old, pin2_new)
code = code.replace(admin_email_old, admin_email_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print('Added onFieldSubmitted to OTP and Login fields')
