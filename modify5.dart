import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Imports
  if (!content.contains("import 'package:file_picker/file_picker.dart';")) {
    content = content.replaceFirst(
      "import 'package:image_picker/image_picker.dart';",
      "import 'package:image_picker/image_picker.dart';\nimport 'package:file_picker/file_picker.dart';\nimport 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';"
    );
  }

  // 2. Global variables for Students and Menu
  String globals = '''
class RegisteredStudent {
  final String name;
  final String roomNo;
  final File photo;
  RegisteredStudent(this.name, this.roomNo, this.photo);
}
List<RegisteredStudent> globalRegisteredStudents = [];

File? globalMenuFile;
bool globalMenuIsPdf = false;
''';
  if (!content.contains('class RegisteredStudent {')) {
    content = content.replaceFirst('Set<String> globalAdminHiddenNotices = {};', 'Set<String> globalAdminHiddenNotices = {};\n' + globals);
  }

  // 3. Deduplication logic in LoginScreen
  String loginMatch = '''      if (nameCtrl.text.isNotEmpty && roomNoCtrl.text.isNotEmpty && pinCtrl.text.length == 4) {
        if (_studentPhoto == null) {
          setState(() => _error = "Please upload student photo.");
          return;
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StudentDashboardScreen(
          name: nameCtrl.text,
          roomNo: roomNoCtrl.text,
          photo: _studentPhoto!,
        )));
      }''';
  String newLoginMatch = '''      if (nameCtrl.text.isNotEmpty && roomNoCtrl.text.isNotEmpty && pinCtrl.text.length == 4) {
        if (_studentPhoto == null) {
          setState(() => _error = "Please upload student photo.");
          return;
        }
        
        bool exists = globalRegisteredStudents.any((s) => s.roomNo == roomNoCtrl.text);
        if (!exists) {
          globalRegisteredStudents.add(RegisteredStudent(nameCtrl.text, roomNoCtrl.text, _studentPhoto!));
        }
        
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StudentDashboardScreen(
          name: nameCtrl.text,
          roomNo: roomNoCtrl.text,
          photo: _studentPhoto!,
        )));
      }''';
  content = content.replaceFirst(loginMatch, newLoginMatch);

  // 4. Admin Registered Students Screen
  String adminRegScreen = '''
class AdminRegisteredStudentsScreen extends StatelessWidget {
  const AdminRegisteredStudentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(title: const Text("Registered Students"), backgroundColor: brandOrange, foregroundColor: Colors.white),
      body: globalRegisteredStudents.isEmpty ? const Center(child: Text("No students registered yet.", style: TextStyle(color: brandGray))) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: globalRegisteredStudents.length,
        itemBuilder: (context, index) {
          final s = globalRegisteredStudents[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(backgroundImage: FileImage(s.photo), radius: 24),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
              subtitle: Text("Room: \${s.roomNo}", style: const TextStyle(color: brandGray)),
            )
          );
        }
      )
    );
  }
}
''';
  if (!content.contains('class AdminRegisteredStudentsScreen')) {
    content = content + '\n' + adminRegScreen;
  }

  // 5. Connect "View All Register student" to Screen
  String oldRegDrawer = '''            ListTile(
              leading: const Icon(Icons.group, color: brandDark),
              title: const Text('View All Register Student', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); },
            ),''';
  String newRegDrawer = '''            ListTile(
              leading: const Icon(Icons.group, color: brandDark),
              title: const Text('View All Register Student', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRegisteredStudentsScreen()));
              },
            ),''';
  content = content.replaceFirst(oldRegDrawer, newRegDrawer);

  // 6. Connect "Set Menu" to FilePicker
  String oldSetMenu = '''            ListTile(
              leading: const Icon(Icons.set_meal, color: brandDark),
              title: const Text('Set Menu', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); },
            ),''';
  String newSetMenu = '''            ListTile(
              leading: const Icon(Icons.set_meal, color: brandDark),
              title: const Text('Set Menu', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                );
                if (result != null && result.files.single.path != null) {
                  setState(() {
                    globalMenuFile = File(result.files.single.path!);
                    globalMenuIsPdf = result.files.single.extension?.toLowerCase() == 'pdf';
                  });
                }
              },
            ),''';
  content = content.replaceFirst(oldSetMenu, newSetMenu);

  // 7. ViewMenuTab Widget helper method
  String globalMenuWidget = '''
class ViewMenuTab extends StatelessWidget {
  const ViewMenuTab({super.key});
  @override
  Widget build(BuildContext context) {
    if (globalMenuFile == null) {
      return const Center(child: Text("No menu uploaded yet.", style: TextStyle(color: brandGray)));
    }
    if (globalMenuIsPdf) {
      return SfPdfViewer.file(globalMenuFile!);
    } else {
      return InteractiveViewer(child: Center(child: Image.file(globalMenuFile!)));
    }
  }
}
''';
  if (!content.contains('class ViewMenuTab extends')) {
    content = content.replaceFirst('class NoticeItem {', globalMenuWidget + '\nclass NoticeItem {');
  }

  // 8. Replace Menu Content with ViewMenuTab()
  String oldMenuContent = '''const Center(child: Text("Menu Content", style: TextStyle(color: brandGray)))''';
  String newMenuContent = '''const ViewMenuTab()''';
  content = content.replaceAll(oldMenuContent, newMenuContent);

  file.writeAsStringSync(content);
}
