import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

student_logic_old = """    if (existingStudent != null) {
      if (existingStudent.pin.isEmpty) {
        existingStudent.pin = typedPin;
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

student_logic_new = """    if (existingStudent != null) {
      if (existingStudent.pin.isEmpty) {
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

code = code.replace(student_logic_old, student_logic_new)

# Similarly, when creating a new student because the room has space
student_new_old = """      globalRegisteredStudents.add(
        RegisteredStudent(typedName, selectedRoom!, studentPhotoUrl, typedPin),
      );"""

student_new_new = """      if (typedPin.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be 8 characters'), backgroundColor: Colors.redAccent));
        return;
      }
      if (typedPin != _studentRePinController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
        return;
      }
      globalRegisteredStudents.add(
        RegisteredStudent(typedName, selectedRoom!, studentPhotoUrl, typedPin, email: _studentEmailController.text.trim()),
      );"""

code = code.replace(student_new_old, student_new_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Patching logic part 2 complete")
