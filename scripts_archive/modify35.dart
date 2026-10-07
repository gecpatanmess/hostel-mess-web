import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // Add selectedStudentName to state
  String stateDecl = '''
class _LoginScreenState extends State<LoginScreen> {
  bool isStudent = true;
  bool isStudentPinVisible = false;
  bool isAdminPassVisible = false;

  final _studentFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  // Controllers to fetch data
  final TextEditingController _studentNameController = TextEditingController();
''';

  String newStateDecl = '''
class _LoginScreenState extends State<LoginScreen> {
  bool isStudent = true;
  bool isStudentPinVisible = false;
  bool isAdminPassVisible = false;
  String? selectedStudentName;

  final _studentFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  // Controllers to fetch data
  final TextEditingController _studentNameController = TextEditingController();
''';

  content = content.replaceFirst(stateDecl, newStateDecl);

  // Replace _handleStudentLogin name grabbing
  String handleLoginTarget = '''
    if (selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a room'), backgroundColor: Colors.redAccent));
      return;
    }

    String typedName = _studentNameController.text.trim();
    String typedPin = _studentPinController.text.trim();
''';
  
  String handleLoginReplacement = '''
    if (selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a room'), backgroundColor: Colors.redAccent));
      return;
    }
    if (selectedStudentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your name'), backgroundColor: Colors.redAccent));
      return;
    }

    String typedName = selectedStudentName!;
    String typedPin = _studentPinController.text.trim();
''';
  content = content.replaceFirst(handleLoginTarget, handleLoginReplacement);

  // When room is selected, reset selectedStudentName
  String dropdownRoomTarget = '''
      onChanged: (value) {
        setState(() {
          selectedRoom = value as String?;
        });
      },
''';
  String dropdownRoomReplacement = '''
      onChanged: (value) {
        setState(() {
          selectedRoom = value as String?;
          selectedStudentName = null;
        });
      },
''';
  content = content.replaceFirst(dropdownRoomTarget, dropdownRoomReplacement);

  // Replace Name input UI
  String nameInputTarget = '''
            _buildInputField(
              controller: _studentNameController,
              label: "Full Name",
              hintText: "Enter your Name",
              icon: Icons.badge_outlined,
            ),
''';

  String nameInputReplacement = '''
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Full Name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: brandInputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedStudentName,
                    hint: const Text("Select Name", style: TextStyle(color: brandGray, fontSize: 14)),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined, color: brandGray),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: selectedRoom == null ? [] : globalRegisteredStudents
                        .where((s) => s.roomNo == selectedRoom)
                        .map((e) => e.name)
                        .toSet()
                        .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedStudentName = val;
                      });
                    },
                    validator: (val) => val == null ? "Please select your name" : null,
                  ),
                ),
              ]
            ),
''';
  content = content.replaceFirst(nameInputTarget, nameInputReplacement);

  file.writeAsStringSync(content);
}
