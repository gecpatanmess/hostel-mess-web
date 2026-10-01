import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  String syncServiceCode = '''
ValueNotifier<int> globalSyncTrigger = ValueNotifier<int>(0);

class SyncService {
  static final _dbRef = FirebaseDatabase.instance.ref('hostelData');
  static bool _isSyncingIn = false;
  static int _lastHash = 0;
  
  static int _computeHash(Map<String, dynamic> data) {
    return jsonEncode(data).hashCode;
  }
  
  static Future<void> pushAll() async {
    if (_isSyncingIn) return;
    
    Map<String, dynamic> data = {};
    
    List<Map<String, dynamic>> studentsList = [];
    for (var s in globalRegisteredStudents) {
      String photoBase64 = "";
      if (!kIsWeb && s.photo.existsSync()) {
        try {
          // Keep base64 short or just use a placeholder if hashing is too slow. 
          // Actually, reading file every second is bad.
          // Let's just track the path length for hash.
          photoBase64 = s.photo.path;
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
    
    Map<String, dynamic> attendanceData = {};
    globalAttendanceMap.forEach((k, v) {
      attendanceData[k] = {'l': v.l, 'd': v.d};
    });
    data['attendance'] = attendanceData;
    
    data['paid'] = globalMonthlyPaid;
    
    List<Map<String, dynamic>> adminsList = [];
    for(var a in globalAdmins) adminsList.add(a.toJson());
    data['admins'] = adminsList;
    
    data['polls'] = {'L': todayPollVotes['L'], 'D': todayPollVotes['D']};
    
    List<Map<String, dynamic>> nList = [];
    for(var n in globalNotices) nList.add(n.toJson());
    data['notices'] = nList;

    int currentHash = _computeHash(data);
    if (currentHash == _lastHash) return; // No changes!
    _lastHash = currentHash;

    // Wait, we need real base64 for upload.
    for (var s in data['students']) {
      if (s['photoBase64'].isNotEmpty && !kIsWeb) {
        try {
          File f = File(s['photoBase64']);
          if(f.existsSync()) {
            s['photoBase64'] = base64Encode(await f.readAsBytes());
          } else {
            s['photoBase64'] = "";
          }
        } catch(e){
          s['photoBase64'] = "";
        }
      }
    }

    try {
      await _dbRef.set(data);
    } catch (e) {
      print("Push Error: \$e");
    }
  }
  
  static void listen() {
    _dbRef.onValue.listen((event) async {
      final snap = event.snapshot;
      if (snap.value == null) return;
      
      _isSyncingIn = true;
      try {
        Map<dynamic, dynamic> rawData = snap.value as Map<dynamic, dynamic>;
        
        // Convert to Map<String, dynamic> safely
        Map<String, dynamic> data = jsonDecode(jsonEncode(rawData));
        
        _lastHash = _computeHash(data); // update hash so we don't push it back

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
    
    // Start dirty check polling
    Timer.periodic(const Duration(seconds: 1), (timer) {
      pushAll();
    });
  }
}
''';

  // We completely replace the old SyncService with this one if it exists
  content = content.replaceFirst(
    RegExp(r'ValueNotifier<int> globalSyncTrigger = ValueNotifier<int>\(0\);[\s\S]*?class MyApp extends StatelessWidget \{'),
    syncServiceCode + "\nclass MyApp extends StatelessWidget {"
  );

  File('lib/main.dart').writeAsStringSync(content);
}
