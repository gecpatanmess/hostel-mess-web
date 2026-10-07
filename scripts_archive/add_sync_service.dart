import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  // 1. Add imports if needed
  if (!content.contains("import 'package:path_provider/path_provider.dart';")) {
    content = content.replaceFirst(
      "import 'dart:convert';",
      "import 'dart:convert';\nimport 'package:path_provider/path_provider.dart';"
    );
  }
  
  // 2. Add SyncService and globalSyncTrigger
  String syncServiceCode = '''
ValueNotifier<int> globalSyncTrigger = ValueNotifier<int>(0);

class SyncService {
  static final _dbRef = FirebaseDatabase.instance.ref('hostelData');
  static bool _isSyncingIn = false;
  
  static Future<void> pushAll() async {
    if (_isSyncingIn) return;
    
    Map<String, dynamic> data = {};
    
    // Students
    List<Map<String, dynamic>> studentsList = [];
    for (var s in globalRegisteredStudents) {
      String photoBase64 = "";
      if (!kIsWeb && s.photo.existsSync()) {
        try {
          photoBase64 = base64Encode(await s.photo.readAsBytes());
        } catch(e){}
      }
      studentsList.add({
        'name': s.name,
        'roomNo': s.roomNo,
        'pin': s.pin,
        'photoBase64': photoBase64,
      });
    }
    data['students'] = studentsList;
    
    // Attendance
    Map<String, dynamic> attendanceData = {};
    globalAttendanceMap.forEach((k, v) {
      attendanceData[k] = {'l': v.l, 'd': v.d};
    });
    data['attendance'] = attendanceData;
    
    // Paid
    data['paid'] = globalMonthlyPaid;
    
    // Admins
    List<Map<String, dynamic>> adminsList = [];
    for(var a in globalAdmins) adminsList.add(a.toJson());
    data['admins'] = adminsList;
    
    // Polls
    data['polls'] = {'L': todayPollVotes['L'], 'D': todayPollVotes['D']};
    
    // Notices
    List<Map<String, dynamic>> nList = [];
    for(var n in globalNotices) nList.add(n.toJson());
    data['notices'] = nList;

    await _dbRef.set(data);
  }
  
  static void listen() {
    _dbRef.onValue.listen((event) async {
      final snap = event.snapshot;
      if (snap.value == null) return;
      
      _isSyncingIn = true;
      try {
        Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
        
        if (data['admins'] != null) {
          globalAdmins.clear();
          for(var a in (data['admins'] as List)) {
            globalAdmins.add(AdminUser.fromJson(Map<String,dynamic>.from(a)));
          }
        }
        
        if (data['paid'] != null) {
          globalMonthlyPaid.clear();
          (data['paid'] as Map).forEach((k, v) {
            globalMonthlyPaid[k.toString()] = (v as num).toInt();
          });
        }
        
        if (data['attendance'] != null) {
          globalAttendanceMap.clear();
          (data['attendance'] as Map).forEach((k, v) {
            var rec = DailyRecord();
            rec.l = v['l'] ?? '';
            rec.d = v['d'] ?? '';
            globalAttendanceMap[k.toString()] = rec;
          });
        }
        
        if (data['polls'] != null) {
          todayPollVotes['L'] = List<String>.from(data['polls']['L'] ?? []);
          todayPollVotes['D'] = List<String>.from(data['polls']['D'] ?? []);
        }
        
        if (data['notices'] != null) {
          globalNotices.clear();
          for(var n in (data['notices'] as List)) {
            globalNotices.add(Notice.fromJson(Map<String,dynamic>.from(n)));
          }
        }
        
        if (data['students'] != null) {
          globalRegisteredStudents.clear();
          final dir = await getApplicationDocumentsDirectory();
          for(var s in (data['students'] as List)) {
            String name = s['name'];
            String roomNo = s['roomNo'];
            String pin = s['pin'];
            String photoBase64 = s['photoBase64'] ?? '';
            
            File photoFile = File('\${dir.path}/\${roomNo}_\${name.replaceAll(" ", "_")}.jpg');
            if (photoBase64.isNotEmpty && !kIsWeb) {
              await photoFile.writeAsBytes(base64Decode(photoBase64));
            }
            globalRegisteredStudents.add(RegisteredStudent(name, roomNo, photoFile, pin));
          }
        }
        
        await saveRegisteredStudents();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('globalAdmins', globalAdmins.map((a) => jsonEncode(a.toJson())).toList());
        
        globalSyncTrigger.value++;
      } catch(e) {
        print("Sync Listen Error: \$e");
      }
      
      _isSyncingIn = false;
    });
  }
}
''';

  content = content.replaceFirst(
    "class MyApp extends StatelessWidget {", 
    syncServiceCode + "\nclass MyApp extends StatelessWidget {"
  );
  
  // 3. Inject SyncService.listen() in main
  content = content.replaceFirst(
    "print(\"Firebase Initialized Successfully\");",
    "print(\"Firebase Initialized Successfully\");\n    SyncService.listen();"
  );
  
  // 4. Wrap MaterialApp with ValueListenableBuilder
  content = content.replaceFirst(
    "return MaterialApp(",
    "return ValueListenableBuilder<int>(\n      valueListenable: globalSyncTrigger,\n      builder: (context, value, child) {\n        return MaterialApp("
  );
  content = content.replaceFirst(
    "home: const RoleSelectionScreen(),\n    );",
    "home: const RoleSelectionScreen(),\n    );\n      },\n    );"
  );

  File('lib/main.dart').writeAsStringSync(content);
}
