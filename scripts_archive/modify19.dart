import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Update RegisteredStudent model
  String oldModel = '''class RegisteredStudent {
  final String name;
  final String roomNo;
  final File photo;
  RegisteredStudent(this.name, this.roomNo, this.photo);
}''';
  String newModel = '''class RegisteredStudent {
  final String name;
  final String roomNo;
  final File photo;
  final String pin;
  RegisteredStudent(this.name, this.roomNo, this.photo, this.pin);
}''';
  content = content.replaceFirst(oldModel, newModel);

  // 2. Add PIN Controller
  String oldControllers = '''  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();''';
  String newControllers = '''  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentPinController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();''';
  if (!content.contains('_studentPinController')) {
    content = content.replaceFirst(oldControllers, newControllers);
  }

  // 3. Attach Controller to Password Field
  String oldPasswordField = '''            _buildPasswordField(
              label: "4 Digit - PIN",
              hintText: "Enter 4 - digit PIN",''';
  String newPasswordField = '''            _buildPasswordField(
              controller: _studentPinController,
              label: "4 Digit - PIN",
              hintText: "Enter 4 - digit PIN",''';
  content = content.replaceFirst(oldPasswordField, newPasswordField);

  // 4. Update _handleStudentLogin logic
  // We'll replace the entire method safely
  int methodStart = content.indexOf('  void _handleStudentLogin() {');
  int methodEnd = content.indexOf('  void _handleAdminLogin() {');

  if (methodStart != -1 && methodEnd != -1) {
    String newLoginMethod = '''  void _handleStudentLogin() {
    if (!_studentFormKey.currentState!.validate()) return;
    if (selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a room'), backgroundColor: Colors.redAccent));
      return;
    }

    String typedName = _studentNameController.text.trim();
    String typedPin = _studentPinController.text.trim();
    
    var roomStudents = globalRegisteredStudents.where((s) => s.roomNo == selectedRoom!).toList();
    RegisteredStudent? existingStudent;
    try {
      existingStudent = roomStudents.firstWhere((s) => s.name.toLowerCase() == typedName.toLowerCase());
    } catch (e) {
      existingStudent = null;
    }

    if (existingStudent != null) {
      if (existingStudent.pin != typedPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Wrong PIN! Please enter the correct PIN.', style: TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.redAccent)
        );
        return;
      }
      if (studentPhoto == null) {
        studentPhoto = existingStudent.photo;
      }
    } else {
      if (studentPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Please upload a student photo for new registration.', style: TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.redAccent)
        );
        return;
      }
      if (roomStudents.length >= 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('આ રૂમ ફૂલ થઈ ગયો છે (Max 4 students).', style: TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.redAccent)
        );
        return;
      }
      globalRegisteredStudents.add(RegisteredStudent(typedName, selectedRoom!, studentPhoto!, typedPin));
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboardScreen(
          photo: studentPhoto!,
          name: typedName,
          roomNo: selectedRoom!,
        ),
      ),
    );
  }

''';
    content = content.replaceRange(methodStart, methodEnd, newLoginMethod);
  }

  // Also fix the place where globalRegisteredStudents are mocked or added somewhere else, if any. (We don't have mocks).
  file.writeAsStringSync(content);
}
