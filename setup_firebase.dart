import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  // Add imports
  if (!content.contains("import 'package:firebase_core/firebase_core.dart';")) {
    content = content.replaceFirst(
      "import 'dart:convert';",
      "import 'dart:convert';\nimport 'package:firebase_core/firebase_core.dart';\nimport 'package:firebase_database/firebase_database.dart';"
    );
  }

  // Update main function
  String firebaseInit = '''
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCJ2ebzZpVt3rQKMSSRkuH-zh13xu3N6rw",
        appId: "1:947094039187:android:6c2a8906468742c8bdbb66",
        messagingSenderId: "947094039187",
        projectId: "hostel-mess-21845",
        databaseURL: "https://hostel-mess-21845-default-rtdb.firebaseio.com",
      ),
    );
    print("Firebase Initialized Successfully");
  } catch (e) {
    print("Firebase Init Error: \$e");
  }

  _loadFakeStudents();
  await _loadDataFromPrefs();
  runApp(const MyApp());
}
''';

  content = content.replaceFirst(
    RegExp(r'void main\(\) async \{[\s\S]*?runApp\(const MyApp\(\)\);\n\}'),
    firebaseInit.trim()
  );

  File('lib/main.dart').writeAsStringSync(content);
}
