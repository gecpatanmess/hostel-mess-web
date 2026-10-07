import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  String oldLogic = '''    if (_studentFormKey.currentState!.validate()) {
      
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
    }''';

  String newLogic = '''    if (_studentFormKey.currentState!.validate()) {
      String typedName = _studentNameController.text.trim();
      var roomStudents = globalRegisteredStudents.where((s) => s.roomNo == selectedRoom!).toList();
      bool alreadyRegistered = roomStudents.any((s) => s.name.toLowerCase() == typedName.toLowerCase());

      if (!alreadyRegistered) {
        if (roomStudents.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('આ રૂમ ફૂલ થઈ ગયો છે (Max 4 students).', style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
        globalRegisteredStudents.add(RegisteredStudent(typedName, selectedRoom!, studentPhoto!));
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
    }''';

  content = content.replaceFirst(oldLogic, newLogic);
  file.writeAsStringSync(content);
}
