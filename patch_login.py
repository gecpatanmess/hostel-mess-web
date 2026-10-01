import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

target_login = """    String typedName = selectedStudentName!;
    String typedPin = _studentPinController.text.trim();

    var roomStudents = globalRegisteredStudents
        .where((s) => s.roomNo == selectedRoom!)
        .toList();"""
        
replacement_login = """    String typedName = selectedStudentName!;
    String typedPin = _studentPinController.text.trim();
    String hashedTypedPin = hashPassword(typedPin);

    // Explicitly fetch latest from Firebase to prevent Web vs App mismatch bugs
    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData/students').get();
      if (snap.exists && snap.value != null) {
        globalRegisteredStudents.clear();
        for(var s in (snap.value as List)) {
          globalRegisteredStudents.add(RegisteredStudent.fromJson(Map<String,dynamic>.from(s)));
        }
      }
    } catch(e) {}

    var roomStudents = globalRegisteredStudents
        .where((s) => s.roomNo == selectedRoom!)
        .toList();"""

code = code.replace(target_login, replacement_login)

target_login2 = """        if (existingStudent.pin.isEmpty) {
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
        } else if (existingStudent.pin != typedPin) {"""
        
replacement_login2 = """        if (existingStudent.pin.isEmpty) {
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
            const SnackBar(
              content: Text(
                'Password created successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (existingStudent.pin != hashedTypedPin && existingStudent.pin != typedPin) {"""

code = code.replace(target_login2, replacement_login2)

target_login3 = """      } else {
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
      }"""
      
replacement_login3 = """      } else {
        if (studentPhotoUrl == null && !hasSavedStudent) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a photo.'), backgroundColor: Colors.redAccent));
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
      }"""

code = code.replace(target_login3, replacement_login3)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Patched student login")
