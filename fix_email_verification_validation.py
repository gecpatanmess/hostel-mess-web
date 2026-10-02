with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import re

# We want to replace the start of _verifyEmailAndOtp
target = """  /// Validates email via backend, then shows OTP dialog
  Future<void> _verifyEmailAndOtp({required bool isStudentForm}) async {
    final email = isStudentForm
        ? _studentEmailController.text.trim()
        : _adminEmailController.text.trim();"""

replacement = """  /// Validates email via backend, then shows OTP dialog
  Future<void> _verifyEmailAndOtp({required bool isStudentForm}) async {
    if (isStudentForm && !hasSavedStudent) {
      if (selectedRoom == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a room first.'), backgroundColor: Colors.redAccent));
        return;
      }
      if (selectedStudentName == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your name first.'), backgroundColor: Colors.redAccent));
        return;
      }
      String typedPin = _studentPinController.text.trim();
      if (typedPin.length != 8) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be 8 characters.'), backgroundColor: Colors.redAccent));
        return;
      }
      
      try {
        final snap = await FirebaseDatabase.instance.ref('hostelData/students').get();
        if (snap.exists && snap.value != null) {
          globalRegisteredStudents.clear();
          for(var s in (snap.value as List)) {
            globalRegisteredStudents.add(RegisteredStudent.fromJson(Map<String,dynamic>.from(s)));
          }
        }
      } catch(e) {}
      
      var roomStudents = globalRegisteredStudents.where((s) => s.roomNo == selectedRoom!).toList();
      RegisteredStudent? existingStudent;
      try {
        existingStudent = roomStudents.firstWhere((s) => s.name.toLowerCase() == selectedStudentName!.toLowerCase());
      } catch (e) {}

      if (existingStudent != null) {
        if (existingStudent.pin.isEmpty) {
          if (typedPin != _studentRePinController.text) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
            return;
          }
          if (studentPhotoUrl == null && (existingStudent.photoUrl == null || existingStudent.photoUrl!.isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your photo to continue.'), backgroundColor: Colors.redAccent));
            return;
          }
        } else if (existingStudent.pin != typedPin) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong Password! Please enter your correct 8-character password.'), backgroundColor: Colors.redAccent));
          return;
        }
      } else {
        if (typedPin != _studentRePinController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
          return;
        }
        if (studentPhotoUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a student photo for new registration.'), backgroundColor: Colors.redAccent));
          return;
        }
        if (roomStudents.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This room is full (Max 4 students).'), backgroundColor: Colors.redAccent));
          return;
        }
      }
    }

    final email = isStudentForm
        ? _studentEmailController.text.trim()
        : _adminEmailController.text.trim();"""

if target in code:
    code = code.replace(target, replacement)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Replaced _verifyEmailAndOtp validation logic successfully!")
else:
    print("Could not find the target code.")
