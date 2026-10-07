import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  String oldLogin = '''  void _handleStudentLogin() {
    if (studentPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload a student photo', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (_studentFormKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDashboardScreen(
            photo: studentPhoto!,
            name: _studentNameController.text,
            roomNo: selectedRoom!,
          ),
        ),
      );
    }
  }''';

  String newLogin = '''  void _handleStudentLogin() {
    if (studentPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload a student photo', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (_studentFormKey.currentState!.validate()) {
      
      bool exists = globalRegisteredStudents.any((s) => s.roomNo == selectedRoom!);
      if (!exists) {
        globalRegisteredStudents.add(RegisteredStudent(_studentNameController.text, selectedRoom!, studentPhoto!));
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDashboardScreen(
            photo: studentPhoto!,
            name: _studentNameController.text,
            roomNo: selectedRoom!,
          ),
        ),
      );
    }
  }''';

  content = content.replaceFirst(oldLogin, newLogin);
  file.writeAsStringSync(content);
}
