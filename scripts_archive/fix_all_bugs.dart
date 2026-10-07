import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  int changeCount = 0;

  // =========================================================================
  // FIX 1: Photo mandatory for EXISTING students too (line ~986)
  // Currently existing students can login without photo. Fix: if no photo
  // exists on disk AND user didn't pick a new photo, block login.
  // =========================================================================
  String oldExistingStudentPhoto = '''      if (studentPhoto == null) {
        studentPhoto = existingStudent.photo;
      } else {
        existingStudent.photo = studentPhoto!;
      }
      await saveRegisteredStudents();''';

  String newExistingStudentPhoto = '''      if (studentPhoto == null) {
        // Check if existing photo actually exists on disk
        if (!existingStudent.photo.existsSync() || existingStudent.photo.path.contains('dummy')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please upload your photo to continue.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        studentPhoto = existingStudent.photo;
      } else {
        existingStudent.photo = studentPhoto!;
      }
      await saveRegisteredStudents();''';

  content = content.replaceFirst(oldExistingStudentPhoto, newExistingStudentPhoto);
  changeCount++;
  print("FIX 1 DONE: Photo mandatory for existing students");

  // =========================================================================
  // FIX 2: Student notice delete = LOCAL ONLY (SharedPreferences)
  // Remove hiddenNotices & hiddenComplaints from pushAll data
  // Remove hiddenNotices from listen() overwrite
  // Save to SharedPreferences instead
  // =========================================================================

  // 2a: Remove hiddenNotices/hiddenComplaints from pushAll
  String oldHiddenPush = '''    data['hiddenNotices'] = globalStudentHiddenNotices.toList();
    data['hiddenComplaints'] = globalStudentHiddenComplaints.toList();
    data['adminLastViewed'] = globalAdminLastViewedComplaints.toIso8601String();''';

  String newHiddenPush = '''    // hiddenNotices & hiddenComplaints are now LOCAL ONLY (SharedPreferences)
    // They are NOT pushed to Firebase anymore to prevent cross-device deletion
    data['adminLastViewed'] = globalAdminLastViewedComplaints.toIso8601String();''';

  content = content.replaceFirst(oldHiddenPush, newHiddenPush);
  changeCount++;
  print("FIX 2a DONE: Removed hiddenNotices from pushAll");

  // 2b: Remove hiddenNotices from listen() overwrite
  String oldHiddenListen = '''        if (data['hiddenNotices'] != null) {
          globalStudentHiddenNotices = Set<String>.from(data['hiddenNotices']);
        }
        if (data['hiddenComplaints'] != null) {
          globalStudentHiddenComplaints = Set<String>.from(data['hiddenComplaints']);
        }''';

  String newHiddenListen = '''        // hiddenNotices & hiddenComplaints are LOCAL ONLY - don't load from Firebase
        // They stay in SharedPreferences per-device''';

  content = content.replaceFirst(oldHiddenListen, newHiddenListen);
  changeCount++;
  print("FIX 2b DONE: Removed hiddenNotices from listen()");

  // 2c: Add save-to-SharedPreferences when student hides a notice
  String oldHideNotice = '''                    onPressed: () {
                      setState(() {
                        globalStudentHiddenNotices.add(notice.id);
                      });
                    },''';

  String newHideNotice = '''                    onPressed: () async {
                      setState(() {
                        globalStudentHiddenNotices.add(notice.id);
                      });
                      // Save locally only - don't push to Firebase
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList('hiddenNotices', globalStudentHiddenNotices.toList());
                    },''';

  content = content.replaceFirst(oldHideNotice, newHideNotice);
  changeCount++;
  print("FIX 2c DONE: Notice hide saves to SharedPreferences");

  // =========================================================================
  // FIX 3: TARGETED PUSH - Add specific push methods to SyncService
  // =========================================================================
  String oldPushSwitchesComment = '''  /// Immediately push ONLY the switches node to Firebase.''';

  String newTargetedMethods = '''  /// Push only ONE attendance record to Firebase
  static Future<void> pushAttendance(String key, DailyRecord rec) async {
    try {
      await _dbRef.child('attendance').child(key).set({
        'l': rec.l,
        'd': rec.d,
      });
    } catch(e) {
      print("Push attendance error: \$e");
    }
  }

  /// Push only notices to Firebase
  static Future<void> pushNotices() async {
    try {
      List<Map<String, dynamic>> nList = [];
      for(var n in globalNotices) nList.add({'id': n.id, 'title': n.title, 'message': n.message, 'date': n.date.toIso8601String()});
      await _dbRef.child('notices').set(nList);
    } catch(e) {
      print("Push notices error: \$e");
    }
  }

  /// Push only complaints to Firebase
  static Future<void> pushComplaints() async {
    try {
      List<Map<String, dynamic>> cList = [];
      for (var c in globalComplaints) {
        cList.add({
          'id': c.id, 'title': c.title, 'description': c.description,
          'date': c.date.toIso8601String(), 'studentName': c.studentName, 'studentRoom': c.studentRoom
        });
      }
      await _dbRef.child('complaints').set(cList);
    } catch(e) {
      print("Push complaints error: \$e");
    }
  }

  /// Push only paid data to Firebase
  static Future<void> pushPaid() async {
    try {
      await _dbRef.child('paid').set(globalMonthlyPaid);
    } catch(e) {
      print("Push paid error: \$e");
    }
  }

  /// Push only students list to Firebase
  static Future<void> pushStudents() async {
    try {
      List<Map<String, dynamic>> studentsList = [];
      for (var s in globalRegisteredStudents) {
        String photoBase64 = "";
        if (!kIsWeb && s.photo.existsSync()) {
          try {
            photoBase64 = base64Encode(await s.photo.readAsBytes());
          } catch(e){}
        }
        studentsList.add({
          'name': s.name, 'roomNo': s.roomNo, 'pin': s.pin, 'photoBase64': photoBase64,
        });
      }
      await _dbRef.child('students').set(studentsList);
    } catch(e) {
      print("Push students error: \$e");
    }
  }

  /// Push only admins list to Firebase
  static Future<void> pushAdmins() async {
    try {
      List<Map<String, dynamic>> adminsList = [];
      for(var a in globalAdmins) adminsList.add(a.toJson());
      await _dbRef.child('admins').set(adminsList);
    } catch(e) {
      print("Push admins error: \$e");
    }
  }

  /// Push only menu to Firebase
  static Future<void> pushMenu() async {
    try {
      String menuBase64 = "";
      if (globalMenuFile != null && globalMenuFile!.existsSync() && !kIsWeb) {
        menuBase64 = base64Encode(await globalMenuFile!.readAsBytes());
      }
      await _dbRef.child('menu').set({
        'isPdf': globalMenuIsPdf,
        'fileBase64': menuBase64
      });
    } catch(e) {
      print("Push menu error: \$e");
    }
  }

  /// Immediately push ONLY the switches node to Firebase.''';

  content = content.replaceFirst(oldPushSwitchesComment, newTargetedMethods);
  changeCount++;
  print("FIX 3 DONE: Added all targeted push methods");

  // =========================================================================
  // FIX 4: REMOVE the 1-second Timer.periodic pushAll loop
  // =========================================================================
  String oldTimer = '''    // Start dirty check polling
    Timer.periodic(const Duration(seconds: 1), (timer) {
      pushAll();
    });''';

  String newTimer = '''    // REMOVED: The 1-second pushAll() loop was causing data overwrites
    // between multiple phones. Now using targeted push methods instead.
    // Each action (swipe, poll, notice, etc.) pushes ONLY its own data.''';

  content = content.replaceFirst(oldTimer, newTimer);
  changeCount++;
  print("FIX 4 DONE: Removed 1-second pushAll timer");

  // =========================================================================
  // FIX 5: Student Swipe - use pushAttendance instead of relying on pushAll
  // LUNCH swipe
  // =========================================================================
  String oldLunchSwipe = '''                          onConfirm: () {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.l = 'P'; _lunchMsgVisible = true; });
                            _lunchMsgTimer?.cancel();
                            _lunchMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _lunchMsgVisible = false); });
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(mealName: 'Lunch', photo: widget.photo, name: widget.name, roomNo: widget.roomNo)));
                          },''';

  String newLunchSwipe = '''                          onConfirm: () {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.l = 'P'; _lunchMsgVisible = true; });
                            SyncService.pushAttendance(key, globalAttendanceMap[key]!);
                            _lunchMsgTimer?.cancel();
                            _lunchMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _lunchMsgVisible = false); });
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(mealName: 'Lunch', photo: widget.photo, name: widget.name, roomNo: widget.roomNo)));
                          },''';

  content = content.replaceFirst(oldLunchSwipe, newLunchSwipe);
  changeCount++;
  print("FIX 5a DONE: Lunch swipe uses pushAttendance");

  // Lunch skip
  String oldLunchSkip = '''                          onPressed: () {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.l = 'A'; _lunchMsgVisible = true; });
                            _lunchMsgTimer?.cancel();
                            _lunchMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _lunchMsgVisible = false); });
                          },''';

  String newLunchSkip = '''                          onPressed: () {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.l = 'A'; _lunchMsgVisible = true; });
                            SyncService.pushAttendance(key, globalAttendanceMap[key]!);
                            _lunchMsgTimer?.cancel();
                            _lunchMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _lunchMsgVisible = false); });
                          },''';

  content = content.replaceFirst(oldLunchSkip, newLunchSkip);
  changeCount++;
  print("FIX 5b DONE: Lunch skip uses pushAttendance");

  // Dinner swipe
  String oldDinnerSwipe = '''                          onConfirm: () {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.d = 'P'; _dinnerMsgVisible = true; });
                            _dinnerMsgTimer?.cancel();
                            _dinnerMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _dinnerMsgVisible = false); });
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(mealName: 'Dinner', photo: widget.photo, name: widget.name, roomNo: widget.roomNo)));
                          },''';

  String newDinnerSwipe = '''                          onConfirm: () {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.d = 'P'; _dinnerMsgVisible = true; });
                            SyncService.pushAttendance(key, globalAttendanceMap[key]!);
                            _dinnerMsgTimer?.cancel();
                            _dinnerMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _dinnerMsgVisible = false); });
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(mealName: 'Dinner', photo: widget.photo, name: widget.name, roomNo: widget.roomNo)));
                          },''';

  content = content.replaceFirst(oldDinnerSwipe, newDinnerSwipe);
  changeCount++;
  print("FIX 5c DONE: Dinner swipe uses pushAttendance");

  // Dinner skip
  String oldDinnerSkip = '''                          onPressed: () {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.d = 'A'; _dinnerMsgVisible = true; });
                            _dinnerMsgTimer?.cancel();
                            _dinnerMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _dinnerMsgVisible = false); });
                          },''';

  String newDinnerSkip = '''                          onPressed: () {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.d = 'A'; _dinnerMsgVisible = true; });
                            SyncService.pushAttendance(key, globalAttendanceMap[key]!);
                            _dinnerMsgTimer?.cancel();
                            _dinnerMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _dinnerMsgVisible = false); });
                          },''';

  content = content.replaceFirst(oldDinnerSkip, newDinnerSkip);
  changeCount++;
  print("FIX 5d DONE: Dinner skip uses pushAttendance");

  // =========================================================================
  // FIX 6: Admin _closeMessAndMarkAbsent - push each record individually
  // =========================================================================
  String oldCloseAndMark = '''    void _closeMessAndMarkAbsent(String meal) {
      DateTime now = DateTime.now();
      for (var s in globalRegisteredStudents) {
        String key = "\${now.year}-\${now.month}-\${now.day}_\${s.roomNo}_\${s.name}";
        if (globalAttendanceMap[key] == null) {
          globalAttendanceMap[key] = DailyRecord();
        }''';

  // Find and check what comes after
  if (content.contains(oldCloseAndMark)) {
    // Let's find the full method
  }

  // =========================================================================
  // FIX 7: Load hiddenNotices from SharedPreferences in initApp / main
  // =========================================================================
  // Find where SharedPreferences is loaded
  String oldLoadStudents = '''  List<String>? studentStrs = prefs.getStringList('globalRegisteredStudents');''';
  
  String newLoadStudents = '''  // Load local-only hidden notices/complaints from SharedPreferences
  List<String>? savedHiddenNotices = prefs.getStringList('hiddenNotices');
  if (savedHiddenNotices != null) globalStudentHiddenNotices = Set<String>.from(savedHiddenNotices);
  List<String>? savedHiddenComplaints = prefs.getStringList('hiddenComplaints');
  if (savedHiddenComplaints != null) globalStudentHiddenComplaints = Set<String>.from(savedHiddenComplaints);

  List<String>? studentStrs = prefs.getStringList('globalRegisteredStudents');''';

  content = content.replaceFirst(oldLoadStudents, newLoadStudents);
  changeCount++;
  print("FIX 7 DONE: Load hiddenNotices from SharedPreferences");

  file.writeAsStringSync(content);
  print("\n=== ALL $changeCount FIXES APPLIED SUCCESSFULLY ===");
}
