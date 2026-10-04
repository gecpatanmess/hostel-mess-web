import 'dart:io';
import 'dart:async';
import 'notification_service.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'export_service.dart';
import 'splash_screen.dart';
import 'package:flutter/services.dart'; // Added for inputFormatters
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart'; // For OTP/Email verification API calls

const String RENDER_API_URL = "https://gecpatan-mess.onrender.com";
Map<String, DailyRecord> globalApiAttendanceMap = {};
Set<String> _fetchedApiMonths = {};

Future<void> fetchAttendanceMonth(int year, int month) async {
  String monthKey = "$year-$month";
  if (_fetchedApiMonths.contains(monthKey)) return;
  try {
    final dio = Dio();
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.sendTimeout = const Duration(seconds: 10);
    final response = await dio.get('$RENDER_API_URL/attendance-history?year=$year&month=$month');
    if (response.data != null && response.data['success'] == true) {
      List data = response.data['data'];
      for (var item in data) {
         try {
           DateTime itemDate = DateTime.parse(item['attendance_date']).toLocal();
           String key = "${itemDate.year}-${itemDate.month}-${itemDate.day}_${item['room_no']}_${item['student_name']}";
           DailyRecord rec = DailyRecord();
           rec.l = item['lunch_status'] ?? '';
           rec.d = item['dinner_status'] ?? '';
           globalApiAttendanceMap[key] = rec;
         } catch(e) {}
      }
      _fetchedApiMonths.add(monthKey);
    }
  } catch(e) {
    print("API Error: $e");
  }
}

DailyRecord? getAttendanceMerged(String key) {
  DateTime now = DateTime.now();
  String todayPrefix = "${now.year}-${now.month}-${now.day}_";
  if (key.startsWith(todayPrefix)) {
    return globalAttendanceMap[key];
  }
  return globalApiAttendanceMap[key] ?? globalAttendanceMap[key];
}

void forEachMergedAttendance(void Function(String key, DailyRecord rec) action) {
  Set<String> processed = {};
  globalAttendanceMap.forEach((key, rec) {
    DateTime now = DateTime.now();
    String todayPrefix = "${now.year}-${now.month}-${now.day}_";
    if (key.startsWith(todayPrefix)) {
      action(key, rec);
      processed.add(key);
    }
  });
  globalApiAttendanceMap.forEach((key, rec) {
    action(key, rec);
    processed.add(key);
  });
  globalAttendanceMap.forEach((key, rec) {
    if (!processed.contains(key)) {
      action(key, rec);
      processed.add(key);
    }
  });
}

String formatDateTime(DateTime dt) {
  String pad(int n) => n.toString().padLeft(2, '0');
  String period = dt.hour >= 12 ? 'PM' : 'AM';
  int hour12 = dt.hour % 12;
  if (hour12 == 0) hour12 = 12;
  return "${pad(dt.day)}/${pad(dt.month)}/${dt.year} | ${pad(hour12)}:${pad(dt.minute)} $period";
}


String _getMonthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
}

String _getWeekdayName(int weekday) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return days[weekday - 1];
}


class WeeklyMenuEditorWidget extends StatefulWidget {
  const WeeklyMenuEditorWidget({super.key});
  @override
  _WeeklyMenuEditorWidgetState createState() => _WeeklyMenuEditorWidgetState();
}

class _WeeklyMenuEditorWidgetState extends State<WeeklyMenuEditorWidget> {
  int _selectedDay = DateTime.now().weekday;
  final _bfCtrl = TextEditingController();
  final _luCtrl = TextEditingController();
  final _dnCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDayMenu();
  }

  void _loadDayMenu() async {
    setState(() => _isLoading = true);
    
    // Default fallback
    final fallback = defaultWeeklyMenu[_selectedDay] ?? defaultWeeklyMenu[DateTime.monday]!;
    String bf = fallback['breakfast']!;
    String lu = fallback['lunch']!;
    String dn = fallback['dinner']!;

    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData/weekly_template/$_selectedDay').get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        if (data['breakfast'] != null && data['breakfast'].toString().trim().isNotEmpty) bf = data['breakfast'];
        if (data['lunch'] != null && data['lunch'].toString().trim().isNotEmpty) lu = data['lunch'];
        if (data['dinner'] != null && data['dinner'].toString().trim().isNotEmpty) dn = data['dinner'];
      }
    } catch(e) {}

    _bfCtrl.text = bf;
    _luCtrl.text = lu;
    _dnCtrl.text = dn;
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _saveDayMenu() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseDatabase.instance.ref('hostelData/weekly_template/$_selectedDay').set({
        'breakfast': _bfCtrl.text.trim(),
        'lunch': _luCtrl.text.trim(),
        'dinner': _dnCtrl.text.trim(),
      });
      globalSyncTrigger.notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Menu for day $_selectedDay updated!"), backgroundColor: Colors.green));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error updating menu"), backgroundColor: Colors.red));
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Edit Weekly Timetable", style: TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: const InputDecoration(labelText: "Select Day", border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text("Monday (સોમવાર)")),
                DropdownMenuItem(value: 2, child: Text("Tuesday (મંગળવાર)")),
                DropdownMenuItem(value: 3, child: Text("Wednesday (બુધવાર)")),
                DropdownMenuItem(value: 4, child: Text("Thursday (ગુરુવાર)")),
                DropdownMenuItem(value: 5, child: Text("Friday (શુક્રવાર)")),
                DropdownMenuItem(value: 6, child: Text("Saturday (શનિવાર)")),
                DropdownMenuItem(value: 7, child: Text("Sunday (રવિવાર)")),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() { _selectedDay = val; });
                  _loadDayMenu();
                }
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading) ...[
              TextField(controller: _bfCtrl, decoration: const InputDecoration(labelText: "Breakfast", border: OutlineInputBorder()), maxLines: null),
              const SizedBox(height: 12),
              TextField(controller: _luCtrl, decoration: const InputDecoration(labelText: "Lunch", border: OutlineInputBorder()), maxLines: null),
              const SizedBox(height: 12),
              TextField(controller: _dnCtrl, decoration: const InputDecoration(labelText: "Dinner", border: OutlineInputBorder()), maxLines: null),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: brandOrange, foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _saveDayMenu,
          child: const Text("Save for this Day"),
        ),
      ],
    );
  }
}

class ViewMenuTab extends StatelessWidget {
  const ViewMenuTab({super.key});
  @override
  Widget build(BuildContext context) {
    final defaultMenu = defaultWeeklyMenu[DateTime.now().weekday] ?? defaultWeeklyMenu[DateTime.monday]!;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final weekDay = now.weekday;

    return FutureBuilder<List<DataSnapshot>>(
      future: Future.wait([
        FirebaseDatabase.instance.ref('hostelData/weekly_template/$weekDay').get(),
        FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').get(),
      ]),
      builder: (context, snapshot) {
        String bf = defaultMenu['breakfast']!;
        String lu = defaultMenu['lunch']!;
        String dn = defaultMenu['dinner']!;
        
        if (snapshot.hasData) {
          // 1. Weekly template override
          final weekSnap = snapshot.data![0];
          if (weekSnap.exists && weekSnap.value != null) {
            final wData = Map<String, dynamic>.from(weekSnap.value as Map);
            if (wData['breakfast'] != null && wData['breakfast'].toString().trim().isNotEmpty) bf = wData['breakfast'];
            if (wData['lunch'] != null && wData['lunch'].toString().trim().isNotEmpty) lu = wData['lunch'];
            if (wData['dinner'] != null && wData['dinner'].toString().trim().isNotEmpty) dn = wData['dinner'];
          }
          // 2. Daily override
          final daySnap = snapshot.data![1];
          if (daySnap.exists && daySnap.value != null) {
            final dData = Map<String, dynamic>.from(daySnap.value as Map);
            if (dData['breakfast'] != null && dData['breakfast'].toString().trim().isNotEmpty) bf = dData['breakfast'];
            if (dData['lunch'] != null && dData['lunch'].toString().trim().isNotEmpty) lu = dData['lunch'];
            if (dData['dinner'] != null && dData['dinner'].toString().trim().isNotEmpty) dn = dData['dinner'];
          }
        }

        final now = DateTime.now();
        final months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        final days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        String dateStr = "${days[now.weekday]}, ${now.day} ${months[now.month]} ${now.year}";

        // 3 Demo Photos for the cards
         // Breakfast
         // Lunch bowl
         // Dinner spread

        // Original Main Menu Viewer (Hidden by default)
        Widget mediaViewer;
        if (globalMenuIsPdf) {
          if (globalMenuUploadBytes != null) {
            mediaViewer = SizedBox(height: 400, child: SfPdfViewer.memory(globalMenuUploadBytes!));
          } else if (globalMenuUrl != null && globalMenuUrl!.isNotEmpty && globalMenuUrl!.startsWith('http')) {
            mediaViewer = SizedBox(height: 400, child: SfPdfViewer.network(globalMenuUrl!));
          } else if (globalMenuFile != null) {
            mediaViewer = SizedBox(height: 400, child: SfPdfViewer.file(globalMenuFile!));
          } else {
            mediaViewer = const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No menu uploaded", style: TextStyle(color: Colors.white))));
          }
        } else {
          if (globalMenuUploadBytes != null) {
            mediaViewer = InteractiveViewer(child: Center(child: Image.memory(globalMenuUploadBytes!)));
          } else if (globalMenuUrl != null && globalMenuUrl!.isNotEmpty && globalMenuUrl!.startsWith('http')) {
            mediaViewer = InteractiveViewer(child: Center(child: Image.network(globalMenuUrl!)));
          } else if (globalMenuFile != null && !kIsWeb) {
            mediaViewer = InteractiveViewer(child: Center(child: Image.file(globalMenuFile!)));
          } else {
            mediaViewer = const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No menu uploaded", style: TextStyle(color: Colors.white))));
          }
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const Text("🍽️", style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ).createShader(bounds),
                      child: const Text(
                        "TODAY'S MENU",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Breakfast Card
              _buildMealCard(
                icon: "🌅",
                title: "BREAKFAST",
                items: bf,
                color: const Color(0xFFFF6B35),
                
                imageOnRight: true,
              ),
              const SizedBox(height: 16),

              // Lunch Card
              _buildMealCard(
                icon: "☀️",
                title: "LUNCH",
                items: lu,
                color: const Color(0xFF4CAF50),
                
                imageOnRight: false,
              ),
              const SizedBox(height: 16),

              // Dinner Card
              _buildMealCard(
                icon: "🌙",
                title: "DINNER",
                items: dn,
                color: const Color(0xFF7B68EE),
                
                imageOnRight: true,
              ),
              const SizedBox(height: 24),
              
              // Hidden Uploaded Menu Section
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ExpansionTile(
                    title: const Text(
                      "📄 View Original Menu",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Click to view the menu uploaded by Admin",
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white.withOpacity(0.7),
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 500),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                        ),
                        child: mediaViewer,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealCard({
    required String icon,
    required String title,
    required String items,
    required Color color,
    Widget? imageWidget,
    bool imageOnRight = true,
  }) {
    Widget circleImage = Container(
      width: 90, height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        color: color.withOpacity(0.15),
      ),
      child: Center(
        child: Icon(
          title.toLowerCase().contains("breakfast") ? Icons.free_breakfast :
          title.toLowerCase().contains("lunch") ? Icons.lunch_dining : Icons.dinner_dining,
          color: color, size: 40,
        ),
      ),
    );

    // Parse items by comma
    List<String> itemList = items.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    Widget textContent = Expanded(
      child: Column(
        crossAxisAlignment: imageOnRight ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...itemList.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Flexible(child: Text(item, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: imageOnRight
          ? [textContent, const SizedBox(width: 16), circleImage]
          : [circleImage, const SizedBox(width: 16), textContent],
      ),
    );
  }
}
class NoticeItem {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  NoticeItem(this.id, this.title, this.message, this.date);
}

List<NoticeItem> globalNotices = [];

class ComplaintItem {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String studentName;
  final String studentRoom;
  final String? studentPhotoUrl;
  final String? complaintImageUrl;
  ComplaintItem(
    this.id,
    this.title,
    this.description,
    this.date,
    this.studentName,
    this.studentRoom,
    this.studentPhotoUrl,
    [this.complaintImageUrl]
  );
}

List<ComplaintItem> globalComplaints = [];
Set<String> globalStudentHiddenComplaints = {};
Set<String> globalStudentHiddenNotices = {};
Set<String> globalAdminHiddenComplaints = {};
DateTime globalStudentLastViewedNotices = DateTime(2000);

Future<void> saveStudentHiddenComplaints() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('hiddenComplaints', globalStudentHiddenComplaints.toList());
}

Future<void> saveAdminHiddenComplaints() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('adminHiddenComplaints', globalAdminHiddenComplaints.toList());
}
Set<String> globalAdminHiddenNotices = {};

const Map<int, Map<String, String>> defaultWeeklyMenu = {
  DateTime.monday: {
    'breakfast': 'ચા, કોફી અને પૌંઆ',
    'lunch': 'ભીંડી મસાલા, ચણા, દાલ (મીઠી/તીખી), ચાવલ, રોટી, સલાડ',
    'dinner': 'દમ આલુ, વેજ બિરયાની, રોટી, સલાડ',
  },
  DateTime.tuesday: {
    'breakfast': 'ચા, કોફી, મસાલા પુરી/ મેંદુ વડા',
    'lunch': 'કેબીજ મટર, મુંગ, દહીં/છાશ, દાલ (મીઠી/તીખી), ચાવલ, રોટી, સલાડ, છાશ, ગોળ',
    'dinner': 'મિક્સ વેજ, દાલ ફ્રાય, જીરા રાઇસ, રોટી, સલાડ',
  },
  DateTime.wednesday: {
    'breakfast': 'ચા, કોફી, થેપલા/ચિલા',
    'lunch': 'આલુ ગોબી (ફુલાવર), ચણા મસાલા, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ, સલાડ',
    'dinner': 'દાલ બાટી, લસુન ચટણી, પાપડ, લીંબુ',
  },
  DateTime.thursday: {
    'breakfast': 'ચા, કોફી, ઉપમા',
    'lunch': 'ચણા દાલ, બેગન મસાલા/સોયાબીન, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ, સલાડ, ગોળ',
    'dinner': 'પનીર મસાલા, ફ્રાય રાઇસ, રોટી, સલાડ',
  },
  DateTime.friday: {
    'breakfast': 'ચા, કોફી, આલુ પરાઠા/સેન્ડવીચ ઢોકળા',
    'lunch': 'મિક્સ વેજ (ઊંધિયું), તુવેર, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ/દહીં, સલાડ',
    'dinner': 'ભાજી, પરોઠા, પુલાવ સલાડ',
  },
  DateTime.saturday: {
    'breakfast': 'ચા, કોફી, સમોસા/સેવ ખમણી',
    'lunch': 'આલુ પ્યાસ, ચણા/ ચોલી, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ/દહીં, સલાડ, ગોળ',
    'dinner': 'છોલે ભટુરે, પુરી, મીઠી ખીર',
  },
  DateTime.sunday: {
    'breakfast': 'ચા, કોફી, પાપડી/ગાંઠીયા',
    'lunch': 'આલુ ગોબી, કેબીજ મટર, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ, સલાડ',
    'dinner': 'ઇડલી સંભાર, નારિયેળ ચટણી',
  },
};


class RegisteredStudent {
  final String name;
  final String roomNo;
  String? photoUrl;
  String pin;
  String email;
  RegisteredStudent(this.name, this.roomNo, this.photoUrl, this.pin, {this.email = ''});

  Map<String, dynamic> toJson() => {
    'name': name,
    'roomNo': roomNo,
    'photoUrl': photoUrl ?? '',
    'pin': pin,
    'email': email,
  };
  factory RegisteredStudent.fromJson(Map<String, dynamic> json) {
    String parseStr(dynamic val) {
      if (val == null) return '';
      String s = val.toString().trim();
      if (s.toLowerCase() == 'null' || s.isEmpty) return '';
      return s;
    }
    String? parseNullableStr(dynamic val) {
      if (val == null) return null;
      String s = val.toString().trim();
      if (s.toLowerCase() == 'null' || s.isEmpty) return null;
      return s;
    }
    return RegisteredStudent(
      parseStr(json['name']),
      parseStr(json['roomNo']),
      parseNullableStr(json['photoUrl'] ?? json['photo']),
      parseStr(json['pin']),
      email: parseStr(json['email']),
    );
  }

  bool get isValid => name.isNotEmpty && roomNo.isNotEmpty;
}

Future<void> saveRegisteredStudents() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> strs = globalRegisteredStudents.map((s) => jsonEncode(s.toJson())).toList();
  await prefs.setStringList('globalRegisteredStudents', strs);
}

class AdminUser {
  String phone;
  String pin;
  String email;
  AdminUser(this.phone, this.pin, {this.email = ''});

  Map<String, dynamic> toJson() => {'phone': phone, 'pin': pin, 'email': email};
  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(json['phone'], json['pin'], email: json['email'] ?? '');
}
List<AdminUser> globalAdmins = [AdminUser("9586401483", "c984aed014aec7623a54f0591da07a85fd4b762d68a75e0ac3f3d7a45b6a1e4c")];

List<RegisteredStudent> globalRegisteredStudents = [];

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();
int globalAppStartTime = DateTime.now().millisecondsSinceEpoch;

void handleForceLogout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (globalNavigatorKey.currentContext != null) {
    Navigator.pushAndRemoveUntil(
      globalNavigatorKey.currentContext!,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}

bool globalEntryL = false;
bool globalEntryD = false;

class DynamicPoll {
  String id;
  String question;
  List<String> options;
  int startTime;
  int endTime;
  bool isActive;
  Map<String, String> votes;

  DynamicPoll({
    required this.id,
    required this.question,
    required this.options,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.votes,
  });

  factory DynamicPoll.fromJson(Map<dynamic, dynamic> json, String id) {
    Map<String, String> parsedVotes = {};
    if (json['votes'] != null) {
      (json['votes'] as Map).forEach((k, v) {
        parsedVotes[k.toString()] = v.toString();
      });
    }
    List<String> parsedOptions = [];
    if (json['options'] != null) {
      for (var o in (json['options'] as List)) {
        parsedOptions.add(o.toString());
      }
    }
    return DynamicPoll(
      id: id,
      question: json['question']?.toString() ?? '',
      options: parsedOptions,
      startTime: json['startTime'] ?? 0,
      endTime: json['endTime'] ?? 0,
      isActive: json['isActive'] ?? false,
      votes: parsedVotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'votes': votes,
    };
  }
}

class DailyRecord {
  String l = '';
  String d = '';
}

Map<String, DailyRecord> globalAttendanceMap = {};
Map<String, int> globalMonthlyPaid = {};
List<String> hiddenComplaints = [];

File? globalMenuFile;
bool globalMenuIsPdf = false;
Uint8List? globalMenuUploadBytes;
String? globalMenuUrl;

DateTime globalAdminLastViewedComplaints = DateTime(2000);

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
    
    // Initialize Notification Service
    await NotificationService.init();

    try {
      await Supabase.initialize(
        url: 'https://whliroffubcqsalxdqfs.supabase.co',
        anonKey: 'sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe',
      );
      print('Supabase Initialized');
    } catch(e) {
      print('Supabase Init Error: $e');
    }

    SyncService.listen();
  } catch (e) {
    print("Firebase Init Error: $e");
  }

  
  await _loadDataFromPrefs();
  runApp(const MyApp());
}

// Global Brand Colors for consistency
const Color brandOrange = Color(0xFFB74300);
const Color brandBg = Color(0xFFF6F8FC);
const Color brandInputBg = Color(0xFFEFF3FC);
const Color brandDark = Color(0xFF0F172A);
const Color brandGray = Color(0xFF64748B);

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: child,
      ),
    );
  }
}

Widget? initialScreen;

Future<void> _loadDataFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final savedVersion = prefs.getString('installed_version');
    if (savedVersion != currentVersion) {
      await prefs.setString('installed_version', currentVersion);
      if (savedVersion != null) {
        await prefs.remove('userType');
      }
    }
  } catch(e) {}
  List<String>? adminStrs = prefs.getStringList('globalAdmins');
  if (adminStrs != null && adminStrs.isNotEmpty) {
    globalAdmins = adminStrs.map((s) => AdminUser.fromJson(jsonDecode(s))).toList();
  }
  
  // Load local-only hidden notices/complaints from SharedPreferences
  List<String>? savedHiddenNotices = prefs.getStringList('hiddenNotices');
  if (savedHiddenNotices != null) {
    globalStudentHiddenNotices.clear();
    globalStudentHiddenNotices.addAll(savedHiddenNotices);
  }
  List<String>? savedHiddenComplaints = prefs.getStringList('hiddenComplaints');
  if (savedHiddenComplaints != null) {
    globalStudentHiddenComplaints.clear();
    globalStudentHiddenComplaints.addAll(savedHiddenComplaints);
  }
  List<String>? savedAdminHiddenComplaints = prefs.getStringList('adminHiddenComplaints');
  if (savedAdminHiddenComplaints != null) {
    globalAdminHiddenComplaints.clear();
    globalAdminHiddenComplaints.addAll(savedAdminHiddenComplaints);
  }

  List<String>? studentStrs = prefs.getStringList('globalRegisteredStudents');
  if (studentStrs != null && studentStrs.isNotEmpty) {
    // If we have saved students, overwrite the fake ones completely
    globalRegisteredStudents = studentStrs.map((s) => RegisteredStudent.fromJson(jsonDecode(s))).where((s) => s.isValid).toList();
  }
  
  String? userType = prefs.getString('userType');
  if (userType == 'admin') {
    String? phone = prefs.getString('identifier');
    String? photoUrl = prefs.getString('photoPath');
    String? name = prefs.getString('extraInfo');
    if (phone != null && photoUrl != null ) {
      initialScreen = AdminDashboardScreen(
        photoUrl: photoUrl,
        name: name ?? "Admin",
        phone: phone,
      );
    }
  } else if (userType == 'student') {
    String? name = prefs.getString('identifier');
    String? photoUrl = prefs.getString('photoPath');
    String? room = prefs.getString('extraInfo');
    if (name != null && photoUrl != null && room != null ) {
      initialScreen = StudentDashboardScreen(
        photoUrl: photoUrl,
        name: name,
        roomNo: room,
      );
    }
  }
}

ValueNotifier<int> globalSyncTrigger = ValueNotifier<int>(0);

String hashPassword(String password) {
  var bytes = utf8.encode(password);
  var digest = sha256.convert(bytes);
  return digest.toString();
}


int calculatePayableBill(int presentMealsCount) {
  int actualBill = presentMealsCount * 70;
  return math.max(actualBill, 3080);
}

class SyncService {

  static Future<String?> uploadImage(Uint8List bytes) async {
    try {
      final path = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('mess_images').uploadBinary(path, bytes);
      return _supabase.storage.from('mess_images').getPublicUrl(path);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  static final _supabase = Supabase.instance.client;
  static final _dbRef = FirebaseDatabase.instance.ref('hostelData');
  static bool _isSyncingIn = false;
  static bool _hasDownloadedOnce = false;
  static int _lastHash = 0;
  static String _lastMenuPath = "";
  static String _lastDownloadedMenuBase64 = "";
  static bool _switchCooldown = false;
  static bool _pollCooldown = false;

  static Map<String, DynamicPoll> dynamicPolls = {};

  static Future<void> createDynamicPoll(DynamicPoll poll) async {
    try {
      await _dbRef.child('dynamic_polls').child(poll.id).set(poll.toJson());
    } catch(e) {
      print("Create poll error: $e");
    }
  }

  static Future<void> stopDynamicPoll(String id) async {
    try {
      await _dbRef.child('dynamic_polls').child(id).update({'isActive': false});
    } catch(e) {
      print("Stop poll error: $e");
    }
  }

  static Future<void> deleteDynamicPoll(String id) async {
    try {
      if (dynamicPolls.containsKey(id)) {
        dynamicPolls.remove(id);
        globalSyncTrigger.value++;
      }
      await _dbRef.child('dynamic_polls').child(id).remove();
    } catch(e) {
      print("Delete poll error: $e");
    }
  }

  /// Firebase keys cannot contain . # $ [ ] /
  static String pollSafeKey(String key) => key.replaceAll(RegExp(r'[.#$\[\]/]'), '_');

  static Future<void> voteDynamicPoll(String pollId, String studentKey, String option) async {
    studentKey = pollSafeKey(studentKey);
    try {
      if (dynamicPolls[pollId] != null) {
        dynamicPolls[pollId]!.votes[studentKey] = option;
        globalSyncTrigger.value++;
      }
      await _dbRef.child('dynamic_polls').child(pollId).child('votes').child(studentKey).set(option);
    } catch(e) {
      print("Vote poll error: $e");
    }
  }

  static Future<void> removeVoteDynamicPoll(String pollId, String studentKey) async {
    studentKey = pollSafeKey(studentKey);
    try {
      if (dynamicPolls[pollId] != null) {
        dynamicPolls[pollId]!.votes.remove(studentKey);
        globalSyncTrigger.value++;
      }
      await _dbRef.child('dynamic_polls').child(pollId).child('votes').child(studentKey).remove();
    } catch(e) {
      print("Remove vote error: $e");
    }
  }

  /// Push only ONE attendance record to Firebase
  static Future<void> pushAttendance(String key, DailyRecord rec) async {
    try {
      Map<String, dynamic> updateData = {};
      if (rec.l.isNotEmpty) updateData['l'] = rec.l;
      if (rec.d.isNotEmpty) updateData['d'] = rec.d;
      if (updateData.isNotEmpty) {
        await _dbRef.child('attendance').child(key).update(updateData);
      }
      globalSyncTrigger.value++;
    } catch(e) {
      print("Push attendance error: $e");
    }
  }

  /// Push only notices to Firebase
  
  static Future<void> deleteNotice(String id) async {
    try {
      globalNotices.removeWhere((n) => n.id == id);
      globalSyncTrigger.value++;
      await _supabase.from('notices').delete().eq('id', id);
      await _dbRef.child('notices_trigger').set(DateTime.now().millisecondsSinceEpoch);
    } catch(e) {
      print("Delete notice error: $e");
    }
  }

  static Future<void> deleteComplaint(String id) async {
    try {
      globalAdminHiddenComplaints.add(id);
      await saveAdminHiddenComplaints();
      globalSyncTrigger.value++;
    } catch(e) {
      print("Delete complaint error: $e");
    }
  }

  static Future<void> fetchNow() async {
    try {
      // 1. Fetch from Firebase
      final snap = await _dbRef.get();
      if (snap.exists && snap.value != null) {
        Map<dynamic, dynamic> rawData = snap.value as Map<dynamic, dynamic>;
        Map<String, dynamic> data = jsonDecode(jsonEncode(rawData));
        
        if (data.containsKey('admins') && data['admins'] != null) {
          globalAdmins.clear();
          for(var a in (data['admins'] as List)) {
            globalAdmins.add(AdminUser.fromJson(Map<String,dynamic>.from(a)));
          }
        }
        
        globalMonthlyPaid.clear();
        if (data['paid'] != null) {
          (data['paid'] as Map).forEach((k, v) {
            globalMonthlyPaid[k.toString()] = (v as num).toInt();
          });
        }
        
        globalAttendanceMap.clear();
        if (data['attendance'] != null) {
          (data['attendance'] as Map).forEach((k, v) {
            var rec = DailyRecord();
            rec.l = v['l'] ?? '';
            rec.d = v['d'] ?? '';
            globalAttendanceMap[k.toString()] = rec;
          });
        }

        SyncService.dynamicPolls.clear();
        if (data['dynamic_polls'] != null) {
          (data['dynamic_polls'] as Map).forEach((k, v) {
            dynamicPolls[k.toString()] = DynamicPoll.fromJson(v, k.toString());
          });
        }

        globalRegisteredStudents.clear();
        if (data['students'] != null) {
          for(var s in (data['students'] as List)) {
            if (s != null) {
              var st = RegisteredStudent.fromJson(Map<String,dynamic>.from(s));
              if (st.isValid) globalRegisteredStudents.add(st);
            }
          }
        }
        
      }

      // 2. Fetch from Supabase
      final noticesData = await _supabase.from('notices').select();
      globalNotices.clear();
      for(var n in noticesData) {
        globalNotices.add(NoticeItem(n['id'].toString(), n['title'], n['message'], DateTime.parse(n['date'])));
      }

      final complaintsData = await _supabase.from('complaints').select();
      globalComplaints.clear();
      for(var c in complaintsData) {
        String? sPhoto = null;
        try {
          sPhoto = globalRegisteredStudents.firstWhere((s) => s.roomNo == c['student_room'] && s.name == c['student_name']).photoUrl;
        } catch(e){}
        globalComplaints.add(ComplaintItem(
          c['id'].toString(), c['title'], c['description'],
          DateTime.parse(c['date']), c['student_name'], c['student_room'], sPhoto, c['image_url']
        ));
      }

      globalSyncTrigger.value++;
    } catch(e) {
      print("Manual Fetch Error: $e");
    }
  }

  static Future<void> pushNotices() async {
    try {
      for(var n in globalNotices) {
        await _supabase.from('notices').upsert({
          'id': n.id,
          'title': n.title,
          'message': n.message,
          'date': n.date.toIso8601String()
        });
      }
      await _dbRef.child('notices_trigger').set(DateTime.now().millisecondsSinceEpoch);
      globalSyncTrigger.value++;
    } catch(e) {
      print("Push notices error: $e");
    }
  }

  /// Push only complaints to Firebase
  static Future<void> pushComplaints() async {
    try {
      for(var c in globalComplaints) {
        String photoUrl = c.complaintImageUrl ?? "";
        await _supabase.from('complaints').upsert({
          'id': c.id,
          'title': c.title,
          'description': c.description,
          'date': c.date.toIso8601String(),
          'student_name': c.studentName,
          'student_room': c.studentRoom,
          'image_url': photoUrl
        });
      }
      globalSyncTrigger.value++;
    } catch(e) {
      print("Push complaints error: $e");
    }
  }

  /// Push only paid data to Firebase
  static Future<void> pushPaid() async {
    try {
      await _dbRef.child('paid').set(globalMonthlyPaid);
      globalSyncTrigger.value++;
    } catch(e) {
      print("Push paid error: $e");
    }
  }

  /// Push only students list to Firebase
  static Future<void> pushStudents() async {
    try {
      List<Map<String, dynamic>> studentsList = [];
      for (var s in globalRegisteredStudents) {
        String photoUrl = s.photoUrl ?? "";
        studentsList.add({
          'name': s.name, 'roomNo': s.roomNo, 'pin': s.pin, 'photoUrl': photoUrl, 'email': s.email,
        });
      }
      await _dbRef.child('students').set(studentsList);
      globalSyncTrigger.value++;
    } catch(e) {
      print("Push students error: $e");
    }
  }

  /// Push only admins list to Firebase
  static Future<void> pushAdmins() async {
    try {
      List<Map<String, dynamic>> adminsList = [];
      for(var a in globalAdmins) adminsList.add(a.toJson());
      await _dbRef.child('admins').set(adminsList);
      globalSyncTrigger.value++;
    } catch(e) {
      print("Push admins error: $e");
    }
  }

  /// Push only menu to Firebase
  static Future<void> pushMenu() async {
    if (globalMenuFile == null) {
      try {
        await _dbRef.child('menu').remove();
        await _supabase.from('menu').delete().eq('id', 1);
        globalSyncTrigger.value++;
    } catch(e){}
      return;
    }
    try {
      final bytes = await globalMenuFile!.readAsBytes();
      final path = 'menu_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('mess_images').uploadBinary(path, bytes);
      final url = _supabase.storage.from('mess_images').getPublicUrl(path);
      
      await _supabase.from('menu').upsert({
        'id': 1,
        'image_url': url,
        'updated_at': DateTime.now().toIso8601String()
      });
      // Clear legacy firebase node so it doesn't conflict
      await _dbRef.child('menu').remove();
    } catch(e) {
      print("Push menu error: $e");
    }
  }

  /// Immediately push ONLY the switches node to Firebase.
  static Future<void> pushSwitchesNow() async {
    _switchCooldown = true;
    try {
      await _dbRef.child('switches').set({
        'globalEntryL': globalEntryL,
        'globalEntryD': globalEntryD,
      });
      globalSyncTrigger.value++;
    } catch(e) {
      print("Push switches error: $e");
    }
    Future.delayed(const Duration(seconds: 3), () {
      _switchCooldown = false;
    });
  }
  
  static int _computeHash(Map<String, dynamic> data) {
    return jsonEncode(data).hashCode;
  }
  
  static Future<void> pushAll() async {
    if (_isSyncingIn) return;
    if (!_hasDownloadedOnce && globalRegisteredStudents.isEmpty) return; // Prevent wiping cloud on fresh install
    
    Map<String, dynamic> data = {};
    
    List<Map<String, dynamic>> studentsList = [];
    for (var s in globalRegisteredStudents) {
      String photoUrl = s.photoUrl ?? '';
      studentsList.add({
        'name': s.name,
        'roomNo': s.roomNo,
        'pin': s.pin,
        'photoUrl': photoUrl,
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
    
    // NOTE: dynamic_polls are NOT pushed here on purpose.
    // They are written only via targeted updates (createDynamicPoll / voteDynamicPoll /
    // removeVoteDynamicPoll / stopDynamicPoll) so concurrent votes never overwrite each other.
    
    // NOTICES, COMPLAINTS AND MENU ARE NOW IN SUPABASE ONLY.
    // We no longer push them to Firebase.

    data['switches'] = {
      'globalEntryL': globalEntryL,
      'globalEntryD': globalEntryD,
    };

    // hiddenNotices & hiddenComplaints are now LOCAL ONLY (SharedPreferences)
    // They are NOT pushed to Firebase anymore to prevent cross-device deletion
    data['adminLastViewed'] = globalAdminLastViewedComplaints.toIso8601String();

    int currentHash = _computeHash(data);
    if (currentHash == _lastHash) return; // No changes!
    _lastHash = currentHash;

    // Wait, we need real base64 for upload.
    for (var s in data['students']) {
      String photoB64 = s['photoBase64'] ?? s['photoUrl'] ?? '';
      if (photoB64.isNotEmpty && !kIsWeb) {
        try {
          File f = File(photoB64);
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
      await _dbRef.update(data);
    } catch (e) {
      print("Push Error: $e");
    }
  }
  
  
  static bool _supabaseStreamsInitialized = false;

  static void initSupabaseStreams() {
    if (_supabaseStreamsInitialized) return;
    _supabaseStreamsInitialized = true;
    
    _supabase.from('notices').stream(primaryKey: ['id']).listen((data) {
      globalNotices.clear();
      for(var n in data) {
        globalNotices.add(NoticeItem(n['id'].toString(), n['title'], n['message'], DateTime.parse(n['date'])));
      }
      globalSyncTrigger.value++;
    });

    _supabase.from('complaints').stream(primaryKey: ['id']).listen((data) async {
      globalComplaints.clear();
      for(var c in data) {
        String? sPhoto = null;
        try {
          sPhoto = globalRegisteredStudents.firstWhere((s) => s.roomNo == c['student_room'] && s.name == c['student_name']).photoUrl;
        } catch(e){}
        globalComplaints.add(ComplaintItem(
          c['id'].toString(), c['title'], c['description'],
          DateTime.parse(c['date']), c['student_name'], c['student_room'], sPhoto, c['image_url']
        ));
      }
      globalSyncTrigger.value++;
    });

    _supabase.from('menu').stream(primaryKey: ['id']).listen((data) async {
       if (data.isNotEmpty) {
         String imgUrl = data.first['image_url'] ?? '';
         if (imgUrl.isNotEmpty) {
            try {
               final response = await _supabase.storage.from('mess_images').download(imgUrl.split('/').last);
               if(kIsWeb) return;
               final dir = await getApplicationDocumentsDirectory();
               File mFile = File('${dir.path}/mess_menu_supabase.jpg');
               await mFile.writeAsBytes(response);
               globalMenuFile = mFile;
               globalSyncTrigger.value++;
            } catch(e) {}
         } else {
           globalMenuFile = null;
           globalSyncTrigger.value++;
         }
       } else {
         globalMenuFile = null;
         globalSyncTrigger.value++;
       }
    });
  }

  static void listen() {
    initSupabaseStreams();

    _dbRef.onValue.listen((event) async {
      final snap = event.snapshot;
      if (snap.value == null) return;
      
      _isSyncingIn = true;
      _hasDownloadedOnce = true;
      try {
        Map<dynamic, dynamic> rawData = snap.value as Map<dynamic, dynamic>;
        
        // Convert to Map<String, dynamic> safely
        Map<String, dynamic> data = jsonDecode(jsonEncode(rawData));
        
        _lastHash = _computeHash(data); // update hash so we don't push it back

        if (data.containsKey('admins') && data['admins'] != null) {
          globalAdmins.clear();
          for(var a in (data['admins'] as List)) {
            globalAdmins.add(AdminUser.fromJson(Map<String,dynamic>.from(a)));
          }
        }
        
        globalMonthlyPaid.clear();
        if (data['paid'] != null) {
          (data['paid'] as Map).forEach((k, v) {
            globalMonthlyPaid[k.toString()] = (v as num).toInt();
          });
        }
        
        globalAttendanceMap.clear();
        if (data['attendance'] != null) {
          (data['attendance'] as Map).forEach((k, v) {
            var rec = DailyRecord();
            rec.l = v['l'] ?? '';
            rec.d = v['d'] ?? '';
            globalAttendanceMap[k.toString()] = rec;
          });
        }
        
        SyncService.dynamicPolls.clear();
        if (data['dynamic_polls'] != null) {
          (data['dynamic_polls'] as Map).forEach((k, v) {
            dynamicPolls[k.toString()] = DynamicPoll.fromJson(v, k.toString());
          });
        }
        
        if (data['menu'] != null) {
          globalMenuIsPdf = data['menu']['isPdf'] ?? false;
          String menuBase64 = data['menu']['fileBase64'] ?? '';
          if (menuBase64 != _lastDownloadedMenuBase64) {
            _lastDownloadedMenuBase64 = menuBase64;
            if (menuBase64.isNotEmpty && !kIsWeb) {
              if(kIsWeb) return;
               final dir = await getApplicationDocumentsDirectory();
              String ext = globalMenuIsPdf ? 'pdf' : 'jpg';
              File mFile = File('${dir.path}/mess_menu_${DateTime.now().millisecondsSinceEpoch}.$ext');
              await mFile.writeAsBytes(base64Decode(menuBase64));
              globalMenuFile = mFile;
              _lastMenuPath = mFile.path;
            } else {
              globalMenuFile = null;
              _lastMenuPath = "";
            }
          }
        }

        if (data['menu_trigger'] != null || data['notices_trigger'] != null) {
          // If triggers changed, force fetch Supabase data directly
          _supabase.from('menu').select().eq('id', 1).then((resp) {
            if (resp.isNotEmpty) {
               globalMenuUrl = resp.first['image_url'];
               globalMenuIsPdf = (globalMenuUrl ?? '').toLowerCase().contains('.pdf');
            } else {
               globalMenuUrl = null;
            }
            globalSyncTrigger.value++;
          });
          _supabase.from('notices').select().then((resp) {
            globalNotices.clear();
            for(var n in resp) {
              globalNotices.add(NoticeItem(n['id'].toString(), n['title'], n['message'], DateTime.parse(n['date'])));
            }
            globalSyncTrigger.value++;
          });
        }

        if (data['switches'] != null && !_switchCooldown) {
          globalEntryL = data['switches']['globalEntryL'] ?? false;
          globalEntryD = data['switches']['globalEntryD'] ?? false;
        }

        // hiddenNotices & hiddenComplaints are LOCAL ONLY - don't load from Firebase
        // They stay in SharedPreferences per-device
        if (data['adminLastViewed'] != null) {
          globalAdminLastViewedComplaints = DateTime.parse(data['adminLastViewed']);
        }
        
        globalRegisteredStudents.clear();
        if (data['students'] != null) {
          for(var s in (data['students'] as List)) {
            if (s != null) {
              var st = RegisteredStudent.fromJson(Map<String,dynamic>.from(s));
              if (st.isValid) globalRegisteredStudents.add(st);
            }
          }
        }
        
        
        await saveRegisteredStudents();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('globalAdmins', globalAdmins.map((a) => jsonEncode(a.toJson())).toList());
        
        globalSyncTrigger.value++;
      } catch(e) {
        print("Sync Listen Error: $e");
      }
      
      _isSyncingIn = false;
    });
    
    // REMOVED: The 1-second pushAll() loop was causing data overwrites
    // between multiple phones. Now using targeted push methods instead.
    // Each action (swipe, poll, notice, etc.) pushes ONLY its own data.
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: globalSyncTrigger,
      builder: (context, value, child) {
        return MaterialApp(
        navigatorKey: globalNavigatorKey,
      title: 'Hostel Mess Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: brandOrange,
        scaffoldBackgroundColor: brandBg,
        colorScheme: ColorScheme.fromSeed(seedColor: brandOrange),
      ),
      builder: (context, child) {
        return ResponsiveWrapper(child: child!);
      },
      home: SplashScreen(nextScreen: UpdateCheckerWrapper(child: initialScreen ?? const LoginScreen())), 
          );
        },
      );
    }
  }

// =============================================================================
// EMAIL OTP VERIFICATION SERVICE
// =============================================================================
// Render backend URL for Email/OTP verification
const String _backendBaseUrl = 'https://gecpatan-mess.onrender.com';

class EmailOtpService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _backendBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  /// Validate email format + domain via backend
  static Future<Map<String, dynamic>> verifyEmail(String email) async {
    try {
      final response = await _dio.post('/verify-email', data: {'email': email});
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'valid': false, 'message': 'Network error. Please check your connection.'};
    }
  }

  /// Send OTP to the given email
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _dio.post('/send-otp', data: {'email': email});
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'success': false, 'message': 'Network error. Please check your connection.'};
    }
  }

  /// Verify OTP entered by user
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post('/verify-otp', data: {'email': email, 'otp': otp});
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'valid': false, 'message': 'Network error. Please check your connection.'};
    }
  }
}

/// Shows a full-screen OTP verification flow dialog.
/// Returns true if OTP was verified successfully, false otherwise.
Future<bool> showOtpVerificationDialog(BuildContext context, String email) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _OtpVerificationDialog(email: email),
  );
  return result ?? false;
}

class _OtpVerificationDialog extends StatefulWidget {
  final String email;
  const _OtpVerificationDialog({required this.email});
  @override
  State<_OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<_OtpVerificationDialog> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isSending = false;
  bool _isVerifying = false;
  bool _otpSent = false;
  String? _statusMessage;
  bool _isError = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    for (var c in _otpControllers) c.dispose();
    for (var f in _otpFocusNodes) f.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _statusMessage = "Sending OTP to ${widget.email}...";
      _isError = false;
    });

    final result = await EmailOtpService.sendOtp(widget.email);

    setState(() {
      _isSending = false;
      if (result['success'] == true) {
        _otpSent = true;
        _statusMessage = "OTP sent! Check your email inbox.";
        _isError = false;
        _startCooldown();
      } else {
        _statusMessage = result['message'] ?? "Failed to send OTP.";
        _isError = true;
      }
    });
  }

  Future<void> _verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() {
        _statusMessage = "Please enter all 6 digits.";
        _isError = true;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _statusMessage = "Verifying OTP...";
      _isError = false;
    });

    final result = await EmailOtpService.verifyOtp(widget.email, otp);

    setState(() {
      _isVerifying = false;
      if (result['valid'] == true) {
        _statusMessage = "✅ Email verified successfully!";
        _isError = false;
      } else {
        _statusMessage = result['message'] ?? "Invalid OTP.";
        _isError = true;
      }
    });

    if (result['valid'] == true) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE9D2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: brandOrange, size: 32),
              ),
              const SizedBox(height: 20),
              const Text("Email Verification", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: brandDark)),
              const SizedBox(height: 8),
              Text(
                "Enter the 6-digit OTP sent to\n${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: brandGray, height: 1.5),
              ),
              const SizedBox(height: 28),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 44, height: 52,
                    margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                    child: TextFormField(
                      controller: _otpControllers[i],
                      focusNode: _otpFocusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      enabled: _otpSent && !_isVerifying,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: brandInputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: brandOrange, width: 2),
                        ),
                      ),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: brandDark),
                      onChanged: (val) {
                        if (val.isNotEmpty && i < 5) {
                          _otpFocusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          _otpFocusNodes[i - 1].requestFocus();
                        }
                        // Auto-verify when all 6 digits entered
                        if (i == 5 && val.isNotEmpty) {
                          String fullOtp = _otpControllers.map((c) => c.text).join();
                          if (fullOtp.length == 6) _verifyOtp();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Status message
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: _isError ? Colors.redAccent : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isError ? Colors.redAccent : Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_otpSent && !_isVerifying && !_isSending) ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text("Verify OTP", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 14),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive OTP? ", style: TextStyle(fontSize: 13, color: brandGray)),
                  GestureDetector(
                    onTap: (_resendCooldown <= 0 && !_isSending) ? () {
                      for (var c in _otpControllers) c.clear();
                      _sendOtp();
                    } : null,
                    child: Text(
                      _isSending ? "Sending..." : (_resendCooldown > 0 ? "Resend (${_resendCooldown}s)" : "Resend"),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (_resendCooldown <= 0 && !_isSending) ? brandOrange : brandGray,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Cancel
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel", style: TextStyle(color: brandGray, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isStudent = true;
  bool _isCreatingPassword = false;
  bool isStudentPinVisible = false;
  bool isAdminPassVisible = false;
  String? selectedStudentName;

  final _studentFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  // Controllers to fetch data
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentPinController = TextEditingController();
  final TextEditingController _studentRePinController = TextEditingController();
  final TextEditingController _studentEmailController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _adminMobileController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  
  bool isStudentRePinVisible = false;


  bool _studentEmailVerified = false;
  bool _adminEmailVerified = false;
  bool _isVerifyingEmail = false;

  bool hasSavedStudent = false;
  String? savedStudentName;
  String? savedStudentRoom;
  String? savedStudentPhoto;

  bool hasSavedAdmin = false;
  String? savedAdminPhone;
  String? savedAdminName;
  String? savedAdminPhoto;

  String? studentPhotoUrl;
  String? adminPhotoUrl;
  final ImagePicker _picker = ImagePicker();

  String? selectedRoom;
  List<String> get roomNumbers {
    var rooms = globalRegisteredStudents.map((s) => s.roomNo).toSet().toList();
    rooms.sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    return rooms;
  }


  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedStudentName = prefs.getString('last_student_name');
      savedStudentRoom = prefs.getString('last_student_room');
      savedStudentPhoto = prefs.getString('last_student_photo');
      hasSavedStudent = savedStudentName != null && savedStudentName!.isNotEmpty;

      savedAdminPhone = prefs.getString('last_admin_phone');
      savedAdminName = prefs.getString('last_admin_name');
      savedAdminPhoto = prefs.getString('last_admin_photo');
      hasSavedAdmin = savedAdminPhone != null && savedAdminPhone!.isNotEmpty;

      if (hasSavedStudent) {
        selectedRoom = savedStudentRoom;
        selectedStudentName = savedStudentName;
        studentPhotoUrl = savedStudentPhoto;
        isStudent = true;
      }
      if (hasSavedAdmin) {
        _adminMobileController.text = savedAdminPhone!;
        _adminNameController.text = savedAdminName ?? "";
        adminPhotoUrl = savedAdminPhoto;
        isStudent = false;
      }
    });
  }

  void _clearSavedStudent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_student_name');
    await prefs.remove('last_student_room');
    await prefs.remove('last_student_photo');
    setState(() {
      hasSavedStudent = false;
      selectedRoom = null;
      selectedStudentName = null;
      studentPhotoUrl = null;
      _studentPinController.clear();
      _studentEmailVerified = false;
    });
  }

  void _clearSavedAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_admin_phone');
    await prefs.remove('last_admin_name');
    await prefs.remove('last_admin_photo');
    setState(() {
      hasSavedAdmin = false;
      _adminMobileController.clear();
      _adminNameController.clear();
      adminPhotoUrl = null;
      _adminPasswordController.clear();
      _adminEmailVerified = false;
    });
  }

  Future<void> _pickImage(bool isStudentForm) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
        maxWidth: 800,
      );
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading photo... Please wait.'), duration: Duration(seconds: 2)));
        final bytes = await image.readAsBytes();
        final url = await SyncService.uploadImage(bytes);
        if (url != null) {
          setState(() {
            if (isStudentForm) {
              studentPhotoUrl = url;
            } else {
              adminPhotoUrl = url;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed (Storage Error). Check bucket policies.')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// Validates email via backend, then shows OTP dialog
  Future<void> _verifyEmailAndOtp({required bool isStudentForm}) async {
    if (isStudentForm && !hasSavedStudent) {
      if (selectedRoom == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a room first.'), backgroundColor: Colors.redAccent));
        return;
      }
      if (selectedStudentName == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your name first.'), backgroundColor: Colors.redAccent));
        return;
      }
      String typedPin = _studentPinController.text.trim();
      String hashedTypedPin = hashPassword(typedPin);
      if (typedPin.length != 8) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be 8 characters.'), backgroundColor: Colors.redAccent));
        return;
      }
      
      try {
        final snap = await FirebaseDatabase.instance.ref('hostelData/students').get();
        if (snap.exists && snap.value != null) {
          globalRegisteredStudents.clear();
          for(var s in (snap.value as List)) {
            if (s != null) {
              var st = RegisteredStudent.fromJson(Map<String,dynamic>.from(s));
              if (st.isValid) globalRegisteredStudents.add(st);
            }
          }
        }
      } catch(e) {}
      
      var roomStudents = globalRegisteredStudents.where((s) => s.roomNo == selectedRoom!).toList();
      RegisteredStudent? existingStudent;
      try {
        existingStudent = roomStudents.firstWhere((s) => s.name.toLowerCase() == selectedStudentName!.toLowerCase());
      } catch (e) {}

      if (existingStudent != null) {
        if (existingStudent.pin.isEmpty) {
          if (typedPin != _studentRePinController.text) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
            return;
          }
          if (studentPhotoUrl == null && (existingStudent.photoUrl == null || existingStudent.photoUrl!.isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your photo to continue.'), backgroundColor: Colors.redAccent));
            return;
          }
              } else if (existingStudent.pin != typedPin && existingStudent.pin != hashedTypedPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Wrong Password! Please enter your correct 8-character password.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      } else if (existingStudent.pin == typedPin) {
        // Upgrade legacy plaintext to hash
        existingStudent.pin = hashedTypedPin;
      }
      } else {
        if (typedPin != _studentRePinController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
          return;
        }
        if (studentPhotoUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a student photo for new registration.'), backgroundColor: Colors.redAccent));
          return;
        }
        if (roomStudents.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This room is full (Max 4 students).'), backgroundColor: Colors.redAccent));
          return;
        }
      }
    } else if (!isStudentForm && !hasSavedAdmin) {
      if (_adminMobileController.text.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit mobile number.'), backgroundColor: Colors.redAccent));
        return;
      }
      if (_adminNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name.'), backgroundColor: Colors.redAccent));
        return;
      }
      if (_adminPasswordController.text.length != 8) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be exactly 8 characters.'), backgroundColor: Colors.redAccent));
        return;
      }
      if (adminPhotoUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a photo.'), backgroundColor: Colors.redAccent));
        return;
      }
      // Check if admin exists and password matches
      String phone = _adminMobileController.text.trim();
      String pin = _adminPasswordController.text;
      AdminUser? admin;
      try {
        admin = globalAdmins.firstWhere((a) => a.phone == phone);
      } catch (e) {
        admin = null;
      }
      if (admin == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin account not found. Please contact super admin.'), backgroundColor: Colors.redAccent));
        return;
      } else {
        if (admin.pin != hashPassword(pin) && admin.pin != pin) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password!'), backgroundColor: Colors.redAccent));
          return;
        }
      }
    }

    final email = isStudentForm
        ? _studentEmailController.text.trim()
        : _adminEmailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Basic regex check client-side first
    final emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isVerifyingEmail = true);

    // Step 1: Deep email validation via backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking email...'), duration: Duration(seconds: 2)),
    );

    final validationResult = await EmailOtpService.verifyEmail(email);

    if (validationResult['valid'] != true) {
      setState(() => _isVerifyingEmail = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid email: ${validationResult['reason'] ?? validationResult['message'] ?? 'Unknown error'}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isVerifyingEmail = false);

    // Step 2: Send OTP and show verification dialog
    if (!mounted) return;
    final verified = await showOtpVerificationDialog(context, email);

    if (verified) {
      setState(() {
        if (isStudentForm) {
          _studentEmailVerified = true;
        } else {
          _adminEmailVerified = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Email verified successfully!'), backgroundColor: Colors.green),
        );
      }
    }
  }


  Future<void> _handleForgotPassword(bool isStudentReq) async {
    String? emailToSend;
    String? targetIdentifier;
    
    if (isStudentReq) {
      targetIdentifier = hasSavedStudent ? savedStudentName : selectedStudentName;
      if (targetIdentifier == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your name first.")));
        return;
      }
      try {
        var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name == targetIdentifier);
        emailToSend = existingStudent.email;
      } catch (e) {}
    } else {
      targetIdentifier = hasSavedAdmin ? savedAdminPhone : _adminMobileController.text.trim();
      if (targetIdentifier == null || targetIdentifier.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your mobile number first.")));
        return;
      }
      try {
        var admin = globalAdmins.firstWhere((a) => a.phone == targetIdentifier);
        emailToSend = admin.email;
      } catch(e) {}
    }
    
    if (emailToSend == null || emailToSend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email found for this account.'), backgroundColor: Colors.redAccent));
      return;
    }
    
    bool verified = await showOtpVerificationDialog(context, emailToSend);
    if (verified) {
      // Let them reset the password
      TextEditingController newPassCtrl = TextEditingController();
      TextEditingController rePassCtrl = TextEditingController();
      bool resetDone = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Reset Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassCtrl,
                inputFormatters: [LengthLimitingTextInputFormatter(8)],
                decoration: const InputDecoration(hintText: "Enter 8-digit new password"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rePassCtrl,
                inputFormatters: [LengthLimitingTextInputFormatter(8)],
                decoration: const InputDecoration(hintText: "Re-enter password"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (newPassCtrl.text.length != 8) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Password must be exactly 8 characters")));
                  return;
                }
                if (newPassCtrl.text != rePassCtrl.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text("Save"),
            )
          ],
        )
      ) ?? false;
      
      if (resetDone) {
        if (isStudentReq) {
          var existingStudent = globalRegisteredStudents.firstWhere((s) => s.name.toLowerCase() == savedStudentName!.toLowerCase());
          existingStudent.pin = hashPassword(newPassCtrl.text);
          await saveRegisteredStudents();
          await SyncService.pushStudents();
        } else {
          var admin = globalAdmins.firstWhere((a) => a.phone == savedAdminPhone);
          admin.pin = hashPassword(newPassCtrl.text);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('globalAdmins', globalAdmins.map((a) => jsonEncode(a.toJson())).toList());
          await SyncService.pushAdmins();
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset successfully!"), backgroundColor: Colors.green));
      }
    }
  }

  void _handleStudentLogin() async {
    if (!_studentFormKey.currentState!.validate()) return;
    if (selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a room'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (selectedStudentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

        bool needsEmailAndRePin = false;
    try {
      var s = globalRegisteredStudents.firstWhere((st) => st.roomNo == selectedRoom && st.name == selectedStudentName);
      needsEmailAndRePin = s.pin.isEmpty;
    } catch (e) {}

    // Email verification check
    if (!hasSavedStudent && needsEmailAndRePin && !_studentEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email first by clicking "Verify Email"'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    String typedName = selectedStudentName!;
    String typedPin = _studentPinController.text.trim();
    String hashedTypedPin = hashPassword(typedPin);

    // Explicitly fetch latest from Firebase to prevent Web vs App mismatch bugs
    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData/students').get();
      if (snap.exists && snap.value != null) {
        globalRegisteredStudents.clear();
        for(var s in (snap.value as List)) {
          if (s != null) {
            var st = RegisteredStudent.fromJson(Map<String,dynamic>.from(s));
              if (st.isValid) globalRegisteredStudents.add(st);
          }
        }
      }
    } catch(e) {}

    var roomStudents = globalRegisteredStudents
        .where((s) => s.roomNo == selectedRoom!)
        .toList();
    RegisteredStudent? existingStudent;
    try {
      existingStudent = roomStudents.firstWhere(
        (s) => s.name.toLowerCase() == typedName.toLowerCase(),
      );
    } catch (e) {
      existingStudent = null;
    }

    if (existingStudent != null) {
      if (existingStudent.pin.isEmpty) {
        if (typedPin.length != 8) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be 8 characters'), backgroundColor: Colors.redAccent));
          return;
        }
        if (typedPin != _studentRePinController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
          return;
        }
        existingStudent.pin = hashedTypedPin;
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
            } else if (existingStudent.pin != typedPin && existingStudent.pin != hashedTypedPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Wrong Password! Please enter your correct 8-character password.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      } else if (existingStudent.pin == typedPin) {
        // Upgrade legacy plaintext to hash
        existingStudent.pin = hashedTypedPin;
      }
      if (existingStudent.photoUrl == null || existingStudent.photoUrl!.isEmpty) {
        if (studentPhotoUrl == null) {
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
        existingStudent.photoUrl = studentPhotoUrl;
      } else {
        studentPhotoUrl = existingStudent.photoUrl; // Use existing photo unconditionally
      }
      await saveRegisteredStudents();
      await SyncService.pushStudents();
    } else {
      if (studentPhotoUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please upload a student photo for new registration.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (roomStudents.length >= 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'This room is full (Max 4 students).',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (typedPin.length != 8) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be 8 characters'), backgroundColor: Colors.redAccent));
        return;
      }
      if (typedPin != _studentRePinController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
        return;
      }
      globalRegisteredStudents.add(
        RegisteredStudent(typedName, selectedRoom!, studentPhotoUrl, hashedTypedPin, email: _studentEmailController.text.trim()),
      );
      await saveRegisteredStudents();
      await SyncService.pushStudents();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_student_name', typedName);
    await prefs.setString('last_student_room', selectedRoom!);
    await prefs.setString('last_student_photo', studentPhotoUrl ?? '');
    await prefs.setString('userType', 'student');
    await prefs.setString('identifier', typedName);
    await prefs.setString('photoPath', studentPhotoUrl ?? '');
    await prefs.setString('extraInfo', selectedRoom!);
    await NotificationService.saveToken();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboardScreen(
          photoUrl: studentPhotoUrl,
          name: typedName,
          roomNo: selectedRoom!,
        ),
      ),
    );
  }

  void _handleAdminLogin() async {
    if (adminPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please upload an admin photo',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    // Email verification check for admin
    if (!hasSavedAdmin && !_adminEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please verify your email first by clicking "Verify Email"',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (_adminFormKey.currentState!.validate()) {
      String phone = _adminMobileController.text.trim();
      String pin = _adminPasswordController.text;

      // Find admin
      AdminUser? admin;
      try {
        admin = globalAdmins.firstWhere((a) => a.phone == phone);
      } catch (e) {
        admin = null;
      }

      if (admin != null) {
        if (admin.pin == hashPassword(pin) || admin.pin == pin) {
          if (admin.pin == pin) {
            // Upgrade legacy plaintext to hash
            admin.pin = hashPassword(pin);
            final p = await SharedPreferences.getInstance();
            await p.setStringList('globalAdmins', globalAdmins.map((a) => jsonEncode(a.toJson())).toList());
            await SyncService.pushAdmins();
          }
          // Success
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_admin_phone', admin.phone);
          await prefs.setString('last_admin_name', _adminNameController.text);
          await prefs.setString('last_admin_photo', adminPhotoUrl ?? '');
          await prefs.setString('userType', 'admin');
          await prefs.setString('identifier', admin.phone);
          await prefs.setString('photoPath', adminPhotoUrl ?? '');
          await prefs.setString('extraInfo', _adminNameController.text);
          await NotificationService.saveToken();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboardScreen(
                photoUrl: adminPhotoUrl,
                name: _adminNameController.text,
                phone: admin!.phone,
              ),
            ),
          );
        } else {
          // Wrong password
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Invalid Password',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Admin account not found for this mobile number',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Hostel Mess Management",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: brandDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Smart Dining, Attendance & Digital Mess Entry",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: brandGray,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 32),

              if (!hasSavedStudent && !hasSavedAdmin)
                Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: brandInputBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isStudent = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isStudent
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isStudent
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school,
                                size: 20,
                                color: isStudent ? brandOrange : brandGray,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Student",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isStudent
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isStudent ? brandOrange : brandGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isStudent = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !isStudent
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: !isStudent
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.security,
                                size: 20,
                                color: !isStudent ? brandOrange : brandGray,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Admin",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: !isStudent
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: !isStudent ? brandOrange : brandGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Form
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: isStudent ? _buildStudentPortal() : _buildAdminPortal(),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    const Text("Developed by", style: TextStyle(color: brandGray, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Image.asset('assets/mdhk_logo.png', height: 28),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentPortal() {
    bool isRegisteredStudent = false;
    String? existingPhoto;
    if (selectedRoom != null && selectedStudentName != null) {
      try {
        final st = globalRegisteredStudents.firstWhere(
          (s) => s.roomNo == selectedRoom && s.name == selectedStudentName
        );
        if (st.pin.isNotEmpty) {
          isRegisteredStudent = true;
          existingPhoto = st.photoUrl;
        }
      } catch(e) {}
    }
    bool canUploadPhoto = !isRegisteredStudent || (existingPhoto == null || existingPhoto.isEmpty);
    String? displayPhotoUrl = (isRegisteredStudent && !canUploadPhoto) ? existingPhoto : studentPhotoUrl;

    return Container(
      key: const ValueKey("StudentPortal"),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _studentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant, color: brandOrange, size: 22),
                SizedBox(width: 10),
                Text(
                  "Student Portal",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: brandDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: canUploadPhoto ? () => _pickImage(true) : () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot change your photo after registration.'), backgroundColor: brandOrange));
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE9D2),
                            shape: BoxShape.circle,
                            image: (displayPhotoUrl != null && displayPhotoUrl.isNotEmpty) ? DecorationImage(image: NetworkImage(displayPhotoUrl), fit: BoxFit.cover)
                                : null,
                          ),
                          child: (displayPhotoUrl == null || displayPhotoUrl.isEmpty)
                              ? const Icon(
                                  Icons.camera_alt_outlined,
                                  color: brandOrange,
                                  size: 38,
                                )
                              : null,
                        ),
                        if (canUploadPhoto)
                          Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: brandOrange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: brandOrange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Upload Student Photo",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: brandDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (hasSavedStudent) ...[
                Center(child: Text(savedStudentName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
                Center(child: Text("Room: ${savedStudentRoom ?? ''}", style: const TextStyle(fontSize: 14, color: brandGray))),
              ],
              if (!hasSavedStudent) ...[
              _buildDropdownField(),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Full Name",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: brandDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: brandInputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(isExpanded: true,
                    value: (selectedRoom != null && globalRegisteredStudents.where((s) => s.roomNo == selectedRoom).map((e) => e.name).contains(selectedStudentName)) ? selectedStudentName : null,
                    hint: const Text(
                      "Select Name",
                      style: TextStyle(color: brandGray, fontSize: 14),
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: brandGray,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    items: selectedRoom == null
                        ? []
                        : globalRegisteredStudents
                              .where((s) => s.roomNo == selectedRoom)
                              .map((e) => e.name)
                              .toSet()
                              .map(
                                (name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                ),
                              )
                              .toList(),
                                        onChanged: (val) {
                      setState(() {
                        selectedStudentName = val;
                        if (val != null && selectedRoom != null) {
                           try {
                             var s = globalRegisteredStudents.firstWhere((st) => st.roomNo == selectedRoom && st.name == val);
                             _isCreatingPassword = s.pin.isEmpty;
                           } catch (e) {
                             _isCreatingPassword = false;
                           }
                        } else {
                           _isCreatingPassword = false;
                        }
                      });
                    },
                    validator: (val) =>
                        val == null ? "Please select your name" : null,
                  ),
                ),
              ],
            ),
            ],
            const SizedBox(height: 20),
            _buildPasswordField(
              controller: _studentPinController,
              label: "8 Character Password",
              hintText: "Enter 8-character Password",
              icon: Icons.dialpad,
              isStudent: true,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  8,
                ), // strictly limits to 8 characters
              ],
            ),
              if (!hasSavedStudent && _isCreatingPassword) ...[
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _studentRePinController,
                label: "Re-enter Password",
                hintText: "Re-enter 8-character Password",
                icon: Icons.lock_outline,
                isStudent: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(8),
                ],
              ),
            const SizedBox(height: 20),
            // Email Verification Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Email Verification",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: brandDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _studentEmailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_studentEmailVerified,
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Please enter your email'
                            : null,
                        decoration: InputDecoration(
                          hintText: "Enter your email",
                          hintStyle: TextStyle(
                            color: brandGray.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            _studentEmailVerified ? Icons.verified : Icons.email_outlined,
                            color: _studentEmailVerified ? Colors.green : brandGray,
                            size: 22,
                          ),
                          filled: true,
                          fillColor: _studentEmailVerified ? Colors.green.shade50 : brandInputBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _studentEmailVerified ? Colors.green : brandOrange,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: brandDark),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_studentEmailVerified || _isVerifyingEmail)
                            ? null
                            : () => _verifyEmailAndOtp(isStudentForm: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _studentEmailVerified ? Colors.green : brandOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _isVerifyingEmail
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                _studentEmailVerified ? "Verified ✓" : "Verify",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),              ], // End of hasSavedStudent
              if (hasSavedStudent || (!hasSavedStudent && selectedStudentName != null && !_isCreatingPassword)) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword(true),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                  ),
                ),

              ],
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _handleStudentLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (!hasSavedStudent && _isCreatingPassword) ? "Sign Up & Login" : "Student Login",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPortal() {
    return Container(
      key: const ValueKey("AdminPortal"),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _adminFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: brandOrange, size: 22),
                SizedBox(width: 10),
                Text(
                  "Admin Portal",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: brandDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE9D2),
                            shape: BoxShape.circle,
                            image: (adminPhotoUrl != null && adminPhotoUrl!.isNotEmpty) ? DecorationImage(image: NetworkImage(adminPhotoUrl!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: (adminPhotoUrl == null || adminPhotoUrl!.isEmpty)
                              ? const Icon(
                                  Icons.person_outline,
                                  color: brandOrange,
                                  size: 42,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: brandOrange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: brandOrange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Upload Admin Photo",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: brandDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (hasSavedAdmin) ...[
              Center(child: Text(savedAdminName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
              Center(child: Text("Phone: ${savedAdminPhone ?? ''}", style: const TextStyle(fontSize: 14, color: brandGray))),
              const SizedBox(height: 20),
            ],
            if (!hasSavedAdmin) ...[
            _buildInputField(
              controller: _adminMobileController,
              label: "Mobile Number",
              hintText: "Enter your register number",
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _adminNameController,
              label: "Name",
              hintText: "Enter your name",
              icon: Icons.person_outline,
            ),
            ],
            const SizedBox(height: 20),
            _buildPasswordField(
              controller: _adminPasswordController,
              label: "Secure Password",
              hintText: "Enter your password",
              icon: Icons.lock_outline,
              isStudent: false,
            ),
            const SizedBox(height: 20),
            if (!hasSavedAdmin) ...[
            // Email Verification Field for Admin
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Email Verification",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: brandDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adminEmailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_adminEmailVerified,
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Please enter your email'
                            : null,
                        decoration: InputDecoration(
                          hintText: "Enter your email",
                          hintStyle: TextStyle(
                            color: brandGray.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            _adminEmailVerified ? Icons.verified : Icons.email_outlined,
                            color: _adminEmailVerified ? Colors.green : brandGray,
                            size: 22,
                          ),
                          filled: true,
                          fillColor: _adminEmailVerified ? Colors.green.shade50 : brandInputBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _adminEmailVerified ? Colors.green : brandOrange,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: brandDark),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_adminEmailVerified || _isVerifyingEmail)
                            ? null
                            : () => _verifyEmailAndOtp(isStudentForm: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _adminEmailVerified ? Colors.green : brandOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _isVerifyingEmail
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                _adminEmailVerified ? "Verified ✓" : "Verify",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),              ], // End of hasSavedAdmin
              if (hasSavedAdmin) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword(false),
                    child: const Text("Forgot Password?", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                  ),
                ),

              ],
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _handleAdminLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Admin Login",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.login, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Room Number",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: brandDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(isExpanded: true,
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Please select a room' : null,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.door_front_door_outlined,
              color: brandGray,
              size: 22,
            ),
            filled: true,
            fillColor: brandInputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down, color: brandGray),
          hint: Text(
            "Select your room",
            style: TextStyle(
              color: brandGray.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          value: roomNumbers.contains(selectedRoom) ? selectedRoom : null,
          items: roomNumbers.map((String room) {
            return DropdownMenuItem<String>(
              value: room,
              child: Text(
                room,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: brandDark,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedRoom = newValue;
              selectedStudentName = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: brandDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Please enter $label'
              : null,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: brandGray.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icon, color: brandGray, size: 22),
            filled: true,
            fillColor: brandInputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: brandDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hintText,
    required IconData icon,
    required bool isStudent,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    bool isVisible = isStudent ? isStudentPinVisible : isAdminPassVisible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: brandDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: !isVisible,
          obscuringCharacter: '*',
          validator: (value) {
            if (value == null || value.trim().isEmpty)
              return 'Please enter $label';
            if (isStudent && value.trim().length != 8)
              return 'Password must be exactly 8 characters';
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: brandGray.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.normal,
              letterSpacing: 0,
            ),
            prefixIcon: Icon(icon, color: brandGray, size: 22),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: brandGray,
                size: 22,
              ),
              onPressed: () => setState(() {
                if (isStudent) {
                  isStudentPinVisible = !isStudentPinVisible;
                } else {
                  isAdminPassVisible = !isAdminPassVisible;
                }
              }),
            ),
            filled: true,
            fillColor: brandInputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          style: TextStyle(
            fontSize: isVisible ? 15 : 18,
            letterSpacing: isVisible ? 0 : 4,
            fontWeight: FontWeight.w500,
            color: brandDark,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// STUDENT DASHBOARD SCREEN
// -----------------------------------------------------------------------------
class StudentDashboardScreen extends StatefulWidget {
  final String? photoUrl;
  final String name;
  final String roomNo;

  const StudentDashboardScreen({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.roomNo,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _isFetchingData = false;
  @override
  void initState() {
    super.initState();
    globalSyncTrigger.addListener(_onSync);
    // Auto-refresh when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SyncService.fetchNow();
      if (mounted) setState(() { _isFetchingData = true; });
      DateTime now = DateTime.now();
      for (int m = 1; m <= now.month; m++) {
        await fetchAttendanceMonth(now.year, m);
      }
      if (mounted) setState(() { _isFetchingData = false; });
    });
  }

  @override
  void dispose() {
    globalSyncTrigger.removeListener(_onSync);
    _lunchMsgTimer?.cancel();
    _dinnerMsgTimer?.cancel();
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  int _selectedIndex = 0;
  final TextEditingController _newAdminMobileCtrl = TextEditingController();
  final TextEditingController _newAdminPinCtrl = TextEditingController();
  final TextEditingController _changeAdminPinCtrl = TextEditingController();
  final TextEditingController _newAdminEmailCtrl = TextEditingController();


  bool _lunchMsgVisible = true;
  bool _dinnerMsgVisible = true;
  Timer? _lunchMsgTimer;
  Timer? _dinnerMsgTimer;
  DateTime _attendanceMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

    Widget _buildHomeTab() {
    DateTime now = DateTime.now();
    String key = "${now.year}-${now.month}-${now.day}_${widget.roomNo}_${widget.name}";
    DailyRecord todayRecord = globalAttendanceMap[key] ?? DailyRecord();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restaurant, color: brandOrange),
                        SizedBox(width: 8),
                        Text("Today's Attendance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}", style: const TextStyle(color: brandOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const Divider(height: 32),
                
                // LUNCH SECTION - only show when admin has entry ON
                if (globalEntryL) ...[
                  const Text("Lunch", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                  const SizedBox(height: 8),
                  if (todayRecord.l.isNotEmpty && _lunchMsgVisible)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: (todayRecord.l == 'P' ? Colors.green : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(todayRecord.l == 'P' ? Icons.check_circle : Icons.cancel, color: todayRecord.l == 'P' ? Colors.green : Colors.redAccent),
                          const SizedBox(width: 8),
                          Text(todayRecord.l == 'P' ? "Attendance marked! (P)" : "Meal Skipped (A)", style: TextStyle(color: todayRecord.l == 'P' ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (todayRecord.l.isEmpty)
                    Column(
                      children: [
                        SwipeToConfirm(
                          text: "Swipe for Lunch",
                          onConfirm: () async {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.l = 'P'; _lunchMsgVisible = true; });
                            await SyncService.pushAttendance(key, globalAttendanceMap[key]!);
                            _lunchMsgTimer?.cancel();
                            _lunchMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _lunchMsgVisible = false); });
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(mealName: 'Lunch', photoUrl: widget.photoUrl, name: widget.name, roomNo: widget.roomNo)));
                          },
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.l = 'A'; _lunchMsgVisible = true; });
                            await SyncService.pushAttendance(key, globalAttendanceMap[key]!);
                            _lunchMsgTimer?.cancel();
                            _lunchMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _lunchMsgVisible = false); });
                          },
                          icon: const Icon(Icons.cancel, color: Colors.redAccent), label: const Text("Skip Meal", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                ],

                // DINNER SECTION - only show when admin has entry ON
                if (globalEntryD) ...[
                  const Text("Dinner", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                  const SizedBox(height: 8),
                  if (todayRecord.d.isNotEmpty && _dinnerMsgVisible)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: (todayRecord.d == 'P' ? Colors.green : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(todayRecord.d == 'P' ? Icons.check_circle : Icons.cancel, color: todayRecord.d == 'P' ? Colors.green : Colors.redAccent),
                          const SizedBox(width: 8),
                          Text(todayRecord.d == 'P' ? "Attendance marked! (P)" : "Meal Skipped (A)", style: TextStyle(color: todayRecord.d == 'P' ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (todayRecord.d.isEmpty)
                    Column(
                      children: [
                        SwipeToConfirm(
                          text: "Swipe for Dinner",
                          onConfirm: () async {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.d = 'P'; _dinnerMsgVisible = true; });
                            await SyncService.pushAttendance(key, globalAttendanceMap[key]!);
                            _dinnerMsgTimer?.cancel();
                            _dinnerMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _dinnerMsgVisible = false); });
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(mealName: 'Dinner', photoUrl: widget.photoUrl, name: widget.name, roomNo: widget.roomNo)));
                          },
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.d = 'A'; _dinnerMsgVisible = true; });
                            await SyncService.pushAttendance(key, globalAttendanceMap[key]!);
                            _dinnerMsgTimer?.cancel();
                            _dinnerMsgTimer = Timer(const Duration(minutes: 3), () { if (mounted) setState(() => _dinnerMsgVisible = false); });
                          },
                          icon: const Icon(Icons.cancel, color: Colors.redAccent), label: const Text("Skip Meal", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                ],

                // Show "No entry active" when both are OFF
                if (!globalEntryL && !globalEntryD)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text("No mess entry is currently active.", style: TextStyle(color: brandGray, fontSize: 16, fontStyle: FontStyle.italic)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _buildDynamicPolls(),
        _buildAttendanceCard(),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, Color color, {String? subtext}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          if (subtext != null)
            Text(subtext, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    String suffix = "_${widget.roomNo}_${widget.name}";
    int currentMonth = _attendanceMonth.month;
    int currentYear = _attendanceMonth.year;

    int presentDays = 0;
    int absentDays = 0;
    int actualBill = 0;

    forEachMergedAttendance((key, rec) {
      if (!key.endsWith(suffix)) return;
      String datePart = key.split('_')[0];
      List<String> parts = datePart.split('-');
      if (parts.length != 3) return;
      int y = int.tryParse(parts[0]) ?? 0;
      int m = int.tryParse(parts[1]) ?? 0;
      if (y != currentYear || m != currentMonth) return;

      bool dayPresent = (rec.l == 'P' || rec.d == 'P');
      if (dayPresent) {
        presentDays++;
      } else {
        absentDays++;
      }

      if (rec.l == 'P') actualBill += 70;
      if (rec.d == 'P') actualBill += 70;
    });

    int payableBill = 0;
    if (presentDays > 0 || absentDays > 0) {
      payableBill = calculatePayableBill(actualBill ~/ 70);
    }

    String paymentKey = "$currentYear-${currentMonth}_${widget.roomNo}_${widget.name}";
    int paidAmount = globalMonthlyPaid[paymentKey] ?? 0;
    int dueAmount = payableBill - paidAmount;
    if (dueAmount < 0) dueAmount = 0;

    String monthName = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ][currentMonth];

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart, color: brandOrange),
                    SizedBox(width: 8),
                    Text("Attendance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16, color: brandOrange),
                      onPressed: () => setState(() {
                        _attendanceMonth = DateTime(_attendanceMonth.year, _attendanceMonth.month - 1, 1);
                      }),
                    ),
                    Text("$monthName $currentYear", style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16, color: brandOrange),
                      onPressed: () => setState(() {
                        _attendanceMonth = DateTime(_attendanceMonth.year, _attendanceMonth.month + 1, 1);
                      }),
                    ),
                  ],
                )
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: _buildStatBox("Present", "$presentDays Days", Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox("Absent", "$absentDays Days", Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatBox("Payable Bill", "₹$payableBill", brandOrange, subtext: "(Min 22-day rule)")),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox("Actual Bill", "₹$actualBill", brandDark, subtext: "(Real cost)")),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatBox("Paid", "₹$paidAmount", Colors.green, subtext: "(Amount Paid)")),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox("Due (Pending)", "₹$dueAmount", Colors.redAccent, subtext: "(To be paid)")),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentAttendanceScreen(name: widget.name, roomNo: widget.roomNo)));
                },
                icon: const Icon(Icons.list_alt, color: Colors.white),
                label: const Text("View Full Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          ],
        ),
      )
    );
  }

  Widget _buildDynamicPolls() {
    String studentKey = SyncService.pollSafeKey("${widget.roomNo}_${widget.name}");
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();
    
    // Filter active polls
    final polls = SyncService.dynamicPolls.values.where((p) {
      bool isLocked = nowMs > p.endTime || !p.isActive;
      return !isLocked;
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    if (polls.isEmpty) {
      return Card(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text("No polls are currently active.", style: TextStyle(color: brandGray, fontSize: 16)),
          ),
        ),
      );
    }

    return Column(
      children: polls.map((p) {
        bool isLocked = nowMs > p.endTime || !p.isActive;
        int totalVotes = p.votes.length;
        String? myVote = p.votes[studentKey];
        
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.poll, color: brandOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Time: ${TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(p.startTime)).format(context)} - ${TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(p.endTime)).format(context)}",
                  style: const TextStyle(color: brandGray, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Divider(height: 24),
                ...p.options.map((opt) {
                  int optVotes = p.votes.values.where((v) => v == opt).length;
                  double percent = totalVotes == 0 ? 0 : optVotes / totalVotes;
                  bool amI = myVote == opt;
                  
                  return InkWell(
                    onTap: isLocked ? null : () async {
                      if (DateTime.now().millisecondsSinceEpoch > p.endTime || !p.isActive) {
                        setState(() {});
                        return;
                      }
                      if (amI) {
                        await SyncService.removeVoteDynamicPoll(p.id, studentKey);
                      } else {
                        await SyncService.voteDynamicPoll(p.id, studentKey, opt);
                      }
                      setState((){});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Stack(
                        children: [
                          Container(
                            height: 40,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percent,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: amI ? brandOrange.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(opt, style: TextStyle(fontWeight: FontWeight.bold, color: isLocked ? brandGray : brandDark)),
                                    if (amI) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle, size: 16, color: brandOrange)),
                                  ],
                                ),
                                Text("${(percent * 100).toStringAsFixed(1)}%", style: const TextStyle(color: brandDark)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Votes: $totalVotes", style: const TextStyle(color: brandGray, fontSize: 12)),
                    if (isLocked)
                      const Text("Poll Closed", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoticeTab() {
    final visibleNotices = globalNotices
        .where((n) => !globalStudentHiddenNotices.contains(n.id))
        .toList();

    return visibleNotices.isEmpty
        ? const Center(
            child: Text("No new notices.", style: TextStyle(color: brandGray)),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visibleNotices.length,
            itemBuilder: (context, index) {
              final notice = visibleNotices[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFDE9D2),
                    child: Icon(Icons.notifications, color: brandOrange),
                  ),
                  title: Text(
                    notice.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: brandDark,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notice.message,
                        style: const TextStyle(color: brandGray),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatDateTime(notice.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: brandOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () async {
                      setState(() {
                        globalStudentHiddenNotices.add(notice.id);
                      });
                      // Save locally only - don't push to Firebase
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList('hiddenNotices', globalStudentHiddenNotices.toList());
                    },
                  ),
                ),
              );
            },
          );
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userType');
    await prefs.remove('identifier');
    await prefs.remove('photoPath');
    await prefs.remove('extraInfo');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: brandBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: const Text(
          "Student Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () async {
              await SyncService.fetchNow();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: brandOrange),
              accountName: Text(
                widget.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text("Room: ${widget.roomNo}"),
              currentAccountPicture: CircleAvatar(
                child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        widget.photoUrl!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.co_present, color: brandDark),
              title: const Text(
                'My Attendance',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentAttendanceScreen(
                      name: widget.name,
                      roomNo: widget.roomNo,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: brandDark),
              title: const Text(
                'Long Leave',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LongLeaveScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined, color: brandDark),
              title: const Text(
                'Mess Complaints',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentComplaintsScreen(
                      name: widget.name,
                      roomNo: widget.roomNo,
                      photoUrl: widget.photoUrl,
                    ),
                  ),
                );
              },
            ),
            const Divider(),

            ListTile(

              leading: const Icon(Icons.info_outline, color: brandDark),

              title: const Text(

                'About Developers',

                style: TextStyle(fontWeight: FontWeight.w600),

              ),

              onTap: () {

                Navigator.pop(context);

                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDevelopersScreen()));

              },

            ),

            const Divider(),

            ListTile(

              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'LogOut',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _onLogout,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Responsive Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        widget.photoUrl!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome Back,",
                        style: TextStyle(
                          color: brandGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: brandDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3, overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: brandOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Room: ${widget.roomNo}",
                          style: const TextStyle(
                            color: brandOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Body Content
          Expanded(
            child: _selectedIndex == 0
                ? _buildHomeTab()
                : _selectedIndex == 1
                ? _buildNoticeTab()
                : const ViewMenuTab(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() {
            _selectedIndex = i;
            if (i == 1) {
              globalStudentLastViewedNotices = DateTime.now();
            }
          });
        },
        selectedItemColor: brandOrange,
        unselectedItemColor: brandGray,
        backgroundColor: Colors.white,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: globalNotices
                  .where(
                    (n) =>
                        !globalStudentHiddenNotices.contains(n.id) &&
                        n.date.isAfter(globalStudentLastViewedNotices),
                  )
                  .isNotEmpty,
              label: Text(
                globalNotices
                    .where(
                      (n) =>
                          !globalStudentHiddenNotices.contains(n.id) &&
                          n.date.isAfter(globalStudentLastViewedNotices),
                    )
                    .length
                    .toString(),
              ),
              child: const Icon(Icons.notifications),
            ),
            label: "View Notice",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: "View Menu",
          ),
        ],
      ),
        ),
        if (_isFetchingData)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// LONG LEAVE SCREEN (UNDER CONSTRUCTION)
// -----------------------------------------------------------------------------
class LongLeaveScreen extends StatelessWidget {
  const LongLeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: const Text(
          "Long Leave",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: brandOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 72,
                  color: brandOrange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Under Construction 🚧",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: brandDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "The Long Leave application feature is currently under construction and will be available soon.",
                textAlign: TextAlign.center,
                style: TextStyle(color: brandGray, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ADMIN DASHBOARD SCREEN
// -----------------------------------------------------------------------------
class AdminDashboardScreen extends StatefulWidget {
  final String? photoUrl;
  final String name;
  final String phone;

  const AdminDashboardScreen({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.phone,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isFetchingData = false;
  @override
  void initState() {
    super.initState();
    globalSyncTrigger.addListener(_onSync);
    // Auto-refresh when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SyncService.fetchNow();
      if (mounted) setState(() { _isFetchingData = true; });
      DateTime now = DateTime.now();
      for (int m = 1; m <= now.month; m++) {
        await fetchAttendanceMonth(now.year, m);
      }
      if (mounted) setState(() { _isFetchingData = false; });
    });
  }

  @override
  void dispose() {
    globalSyncTrigger.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> _getPendingDues() {
    List<Map<String, dynamic>> pendingList = [];
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    Map<String, Map<String, int>> studentMonthStats = {};

    forEachMergedAttendance((key, rec) {
      List<String> parts = key.split('_');
      if (parts.length >= 3) {
        String datePart = parts[0]; 
        String room = parts[1];
        String name = parts[2];
        
        List<String> dateParts = datePart.split('-');
        if (dateParts.length >= 3) {
          String year = dateParts[0];
          String month = dateParts[1];
          String groupKey = "$year-${month}_${room}_$name";

          studentMonthStats.putIfAbsent(groupKey, () => {'P': 0, 'A': 0});
          if (rec.l == 'P') studentMonthStats[groupKey]!['P'] = (studentMonthStats[groupKey]!['P']! + 1);
          if (rec.l == 'A') studentMonthStats[groupKey]!['A'] = (studentMonthStats[groupKey]!['A']! + 1);
          if (rec.d == 'P') studentMonthStats[groupKey]!['P'] = (studentMonthStats[groupKey]!['P']! + 1);
          if (rec.d == 'A') studentMonthStats[groupKey]!['A'] = (studentMonthStats[groupKey]!['A']! + 1);
        }
      }
    });

    studentMonthStats.forEach((groupKey, counts) {
      if (counts['P'] == 0 && counts['A'] == 0) return;
      
      List<String> parts = groupKey.split('_');
      String yearMonth = parts[0];
      String room = parts[1];
      String name = parts[2];

      // Skip the current month - only show past months
      DateTime now = DateTime.now();
      String currentMonthKey = "${now.year}-${now.month}";
      if (yearMonth == currentMonthKey) return;

      List<String> ymParts = yearMonth.split('-');
      String year = ymParts[0];
      int mIdx = int.tryParse(ymParts[1]) ?? 1;
      String monthName = months[mIdx - 1];

      int payableBill = calculatePayableBill(counts['P']!);

      int paidAmt = globalMonthlyPaid[groupKey] ?? 0;

      if (paidAmt < payableBill) {
        RegisteredStudent? student;
        try {
          student = globalRegisteredStudents.firstWhere((s) => s.roomNo == room && s.name == name);
        } catch(e) {}

        if (student != null) {
          pendingList.add({
            'student': student,
            'monthName': monthName,
            'year': year,
            'payable': payableBill,
            'paid': paidAmt,
            'due': payableBill - paidAmt,
          });
        }
      }
    });

    return pendingList;
  }

  int _selectedIndex = 0;
  final TextEditingController _newAdminMobileCtrl = TextEditingController();
  final TextEditingController _newAdminPinCtrl = TextEditingController();
  final TextEditingController _changeAdminPinCtrl = TextEditingController();
  final TextEditingController _newAdminEmailCtrl = TextEditingController();

  Widget _buildAdminsTab() {
    return SingleChildScrollView(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Create New Admin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 20),
          TextField(
            controller: _newAdminMobileCtrl,
            decoration: InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            keyboardType: TextInputType.phone,
            maxLength: 10,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newAdminEmailCtrl,
            decoration: InputDecoration(labelText: "Email ID", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newAdminPinCtrl,
            decoration: InputDecoration(labelText: "8-character Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            maxLength: 8,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (_newAdminMobileCtrl.text.length == 10 && _newAdminPinCtrl.text.length == 8 && _newAdminEmailCtrl.text.contains('@')) {
                  setState(() {
                    globalAdmins.add(AdminUser(_newAdminMobileCtrl.text, hashPassword(_newAdminPinCtrl.text), email: _newAdminEmailCtrl.text.trim()));
                  });
                  final prefs = await SharedPreferences.getInstance();
                  List<String> adminStrings = globalAdmins.map((a) => jsonEncode(a.toJson())).toList();
                  await prefs.setStringList('globalAdmins', adminStrings);
                  await SyncService.pushAdmins();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin created successfully!"), backgroundColor: Colors.green));
                  _newAdminMobileCtrl.clear();
                  _newAdminPinCtrl.clear();
                  _newAdminEmailCtrl.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter valid mobile, email and password."), backgroundColor: Colors.red));
                }
              },
              child: const Text("Create Admin", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildAdminHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...(() {
          final allPolls = SyncService.dynamicPolls.values.toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));
          if (allPolls.isEmpty) return <Widget>[const SizedBox.shrink()];
          
          return <Widget>[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8, top: 8),
              child: Text("Live & Recent Polls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
            ),
            ...allPolls.map<Widget>((p) {
              final bool closed = !p.isActive || DateTime.now().millisecondsSinceEpoch > p.endTime;
              final String fmtStart = TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(p.startTime)).format(context);
              final String fmtEnd = TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(p.endTime)).format(context);
              final String dateStr = "${DateTime.fromMillisecondsSinceEpoch(p.startTime).day}/${DateTime.fromMillisecondsSinceEpoch(p.startTime).month}";
              
              return InkWell(
                onLongPress: closed ? () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Poll?"),
                      content: const Text("Are you sure you want to permanently delete this poll?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await SyncService.deleteDynamicPoll(p.id);
                            setState(() {});
                          },
                          child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                        ),
                      ]
                    )
                  );
                } : null,
                child: Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(p.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            if (closed)
                              const Text("Closed", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                            else
                              const Text("Live", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("Date: $dateStr | Time: $fmtStart - $fmtEnd", style: const TextStyle(color: brandGray, fontSize: 12)),
                        const SizedBox(height: 12),
                        ...p.options.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "$o: ${p.votes.values.where((v) => v == o).length} votes",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )),
                        const SizedBox(height: 8),
                        Text("Total Votes: ${p.votes.length}", style: const TextStyle(fontSize: 13, color: brandGray)),
                        if (!closed) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                              onPressed: () async {
                                await SyncService.stopDynamicPoll(p.id);
                                setState(() {});
                              },
                              child: const Text("End Poll Now"),
                            ),
                          )
                        ] else ...[
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text("Long press to delete", style: TextStyle(fontSize: 11, color: brandGray, fontStyle: FontStyle.italic)),
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const Divider(height: 32),
          ];
        })(),

        ...(() {
          var dues = _getPendingDues();
          if (dues.isEmpty) return <Widget>[const SizedBox.shrink()];
          return <Widget>[
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.black12,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          "Payment Status",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: brandDark,
                          ),
                        ),
                        const Spacer(),
                        if (dues.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.notifications_active, color: Colors.redAccent),
                            tooltip: "Send Reminders",
                            onPressed: () {
                              List<String> names = dues.map((d) => (d['student'] as RegisteredStudent).name).toList();
                              NotificationService.sendPushNotificationToSpecificStudents(
                                names,
                                "Pending Mess Bill",
                                "Please pay your pending mess bill for ${dues[0]['monthName']} ${dues[0]['year']}."
                              );
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reminders sent!")));
                            },
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${dues.length} Pending",
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ...dues.map((due) {
                      RegisteredStudent st = due['student'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: brandOrange,
                              child: (st.photoUrl != null && st.photoUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        st.photoUrl!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
                              radius: 22,
                              
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${st.name} (Room ${st.roomNo})",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${due['monthName']} ${due['year']} - Bill: ₹${due['payable']} | Paid: ₹${due['paid']}",
                                    style: const TextStyle(color: brandGray, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "₹${due['due']}",
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ];
        })(),
      ],
    );
  }

  Widget _buildNoticeTab() {
    final visibleNotices = globalNotices
        .where((n) => !globalAdminHiddenNotices.contains(n.id))
        .toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: visibleNotices.isEmpty
          ? const Center(
              child: Text(
                "No notices yet. Click + to add one.",
                style: TextStyle(color: brandGray),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visibleNotices.length,
              itemBuilder: (context, index) {
                final notice = visibleNotices[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      notice.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notice.message,
                          style: const TextStyle(color: brandGray),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatDateTime(notice.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: brandOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () async {
                        await SyncService.deleteNotice(notice.id);
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: brandOrange,
        onPressed: _showAddNoticeDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddNoticeDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "New Notice",
          style: TextStyle(color: brandDark, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: "Notice Title",
                filled: true,
                fillColor: brandInputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Message",
                filled: true,
                fillColor: brandInputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: brandGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                setState(() {
                  globalNotices.insert(
                    0,
                    NoticeItem(
                      DateTime.now().toString(),
                      titleCtrl.text,
                      msgCtrl.text,
                      DateTime.now(),
                    ),
                  );
                });
                await SyncService.pushNotices();
                NotificationService.sendPushNotificationToStudents(titleCtrl.text, msgCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text(
              "Send Notice",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userType');
    await prefs.remove('identifier');
    await prefs.remove('photoPath');
    await prefs.remove('extraInfo');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _closeMessAndMarkAbsent(String meal) async {
    DateTime now = DateTime.now();
    for (var s in globalRegisteredStudents) {
      String key = "${now.year}-${now.month}-${now.day}_${s.roomNo}_${s.name}";
      if (globalAttendanceMap[key] == null) {
        globalAttendanceMap[key] = DailyRecord();
      }
      if (meal == 'l' &&
          (globalAttendanceMap[key]!.l == '' ||
              globalAttendanceMap[key]!.l == '-')) {
        globalAttendanceMap[key]!.l = 'A';
      } else if (meal == 'd' &&
          (globalAttendanceMap[key]!.d == '' ||
              globalAttendanceMap[key]!.d == '-')) {
        globalAttendanceMap[key]!.d = 'A';
      }
      // Push each record individually to Firebase
      await SyncService.pushAttendance(key, globalAttendanceMap[key]!);
    }
  }

  void _showSetMenuDialog() async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final weekDay = now.weekday;
    final defaultMenu = defaultWeeklyMenu[weekDay] ?? defaultWeeklyMenu[DateTime.monday]!;

    String initialBreakfast = defaultMenu['breakfast']!;
    String initialLunch = defaultMenu['lunch']!;
    String initialDinner = defaultMenu['dinner']!;

    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        if (data['breakfast'] != null && data['breakfast'].toString().trim().isNotEmpty) initialBreakfast = data['breakfast'];
        if (data['lunch'] != null && data['lunch'].toString().trim().isNotEmpty) initialLunch = data['lunch'];
        if (data['dinner'] != null && data['dinner'].toString().trim().isNotEmpty) initialDinner = data['dinner'];
      }
    } catch(e) {}

    final bfCtrl = TextEditingController(text: initialBreakfast);
    final luCtrl = TextEditingController(text: initialLunch);
    final dnCtrl = TextEditingController(text: initialDinner);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Edit Today's Menu", style: TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: bfCtrl, decoration: const InputDecoration(labelText: "Breakfast", border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: luCtrl, decoration: const InputDecoration(labelText: "Lunch", border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: dnCtrl, decoration: const InputDecoration(labelText: "Dinner", border: OutlineInputBorder())),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text("Photo/PDF Menu (Hidden)", style: TextStyle(fontWeight: FontWeight.bold, color: brandGray)),
                    const SizedBox(height: 8),
                    if (globalMenuUrl == null && globalMenuFile == null && globalMenuUploadBytes == null)
                      InkWell(
                        onTap: () async {
                          FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], withData: true);
                          if (result != null) {
                            final file = result.files.single;
                            if (file.bytes != null || file.path != null) {
                              setDialogState(() {
                                if (kIsWeb || file.path == null) {
                                  globalMenuUploadBytes = file.bytes;
                                  globalMenuFile = null;
                                } else {
                                  globalMenuFile = File(file.path!);
                                  globalMenuUploadBytes = file.bytes;
                                }
                                globalMenuIsPdf = file.extension?.toLowerCase() == 'pdf';
                              });
                              setState(() {});
                              await SyncService.pushMenu();
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: brandInputBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: brandOrange.withOpacity(0.5))),
                          child: const Column(
                            children: [
                              Icon(Icons.add_circle_outline, color: brandOrange, size: 32),
                              SizedBox(height: 8),
                              Text("Upload PDF or Image", style: TextStyle(color: brandGray, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: brandInputBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(globalMenuIsPdf ? Icons.picture_as_pdf : Icons.image, color: brandOrange),
                            const SizedBox(width: 8),
                            Expanded(child: Text(globalMenuFile != null ? globalMenuFile!.path.split('/').last.split('\\').last : 'Uploaded Menu', maxLines: 2, overflow: TextOverflow.visible)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                setDialogState(() {
                                  globalMenuFile = null;
                                  globalMenuUrl = null;
                                  globalMenuUploadBytes = null;
                                  globalMenuIsPdf = false;
                                });
                                setState(() {});
                                await SyncService.pushMenu();
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: brandGray)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandOrange, foregroundColor: Colors.white),
                  onPressed: () async {
                    await FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').set({
                      'breakfast': bfCtrl.text.trim(),
                      'lunch': luCtrl.text.trim(),
                      'dinner': dnCtrl.text.trim(),
                    });
                    
                    NotificationService.sendPushNotificationToStudents(
                      "Today's Mess Menu is here!",
                      "Breakfast: ${bfCtrl.text.trim()}\nLunch: ${luCtrl.text.trim()}\nDinner: ${dnCtrl.text.trim()}"
                    );

                    globalSyncTrigger.notifyListeners();
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Today's Menu updated!"), backgroundColor: Colors.green));
                    }
                  },
                  child: const Text("Save Menu"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _showCreatePollDialog() {
    final qCtrl = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: math.min(startTime.hour + 2, 23), minute: startTime.hour + 2 > 23 ? 59 : startTime.minute);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create New Poll'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: qCtrl,
                      decoration: const InputDecoration(labelText: 'Question'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            qCtrl.text = "Today's Lunch?";
                            setDialogState(() {});
                          },
                          child: const Text("Lunch?"),
                        ),
                        TextButton(
                          onPressed: () {
                            qCtrl.text = "Today's Dinner?";
                            setDialogState(() {});
                          },
                          child: const Text("Dinner?"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Start: "),
                        TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(context: context, initialTime: startTime);
                            if (t != null) setDialogState(() => startTime = t);
                          },
                          child: Text(startTime.format(context)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("End: "),
                        TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(context: context, initialTime: endTime);
                            if (t != null) setDialogState(() => endTime = t);
                          },
                          child: Text(endTime.format(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (qCtrl.text.trim().isEmpty) return;
                    
                    final now = DateTime.now();
                    final startDt = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
                    final endDt = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
                    if (!endDt.isAfter(startDt)) {
                      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
                        content: Text("End time must be after Start time"),
                        backgroundColor: Colors.red,
                      ));
                      return;
                    }
                    
                    final poll = DynamicPoll(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      question: qCtrl.text.trim(),
                      options: ["Yes", "No"],
                      startTime: startDt.millisecondsSinceEpoch,
                      endTime: endDt.millisecondsSinceEpoch,
                      isActive: true,
                      votes: {},
                    );
                    
                    Navigator.pop(context);
                    await SyncService.createDynamicPoll(poll);
                    NotificationService.sendPushNotificationToStudents(
                      "New Poll: ${poll.question}",
                      "Open the app to cast your vote."
                    );
                    setState((){});
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: brandBg,
          appBar: AppBar(
            backgroundColor: brandOrange,
            title: const Text(
              "Admin Dashboard",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () async {
              await SyncService.fetchNow();
            },
          ),
        ],
        leading: Builder(
          builder: (context) {
            int unread = globalComplaints
                .where(
                  (c) =>
                      c.date.isAfter(globalAdminLastViewedComplaints) &&
                      !globalAdminHiddenComplaints.contains(c.id),
                )
                .length;
            return IconButton(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread.toString()),
                child: const Icon(Icons.menu, color: Colors.white),
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: brandOrange),
              accountName: Text(
                widget.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: const Text("Administrator"),
              currentAccountPicture: CircleAvatar(
                child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        widget.photoUrl!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
              ),
            ),
            ExpansionTile(
              leading: const Icon(Icons.restaurant, color: brandDark),
              title: const Text(
                'Mess Entry',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                // removed Breakfast switch
                SwitchListTile(
                  title: const Text('Lunch'),
                  activeColor: brandOrange,
                  value: globalEntryL,
                  onChanged: (v) async {
                    setState(() => globalEntryL = v);
                    await SyncService.pushSwitchesNow();
                    if (v == true) {
                      NotificationService.sendPushNotificationToStudents("Lunch Time", "Mess Open");
                    }
                    if (v == false) {
                      _closeMessAndMarkAbsent('l');
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Dinner'),
                  activeColor: brandOrange,
                  value: globalEntryD,
                  onChanged: (v) async {
                    setState(() => globalEntryD = v);
                    await SyncService.pushSwitchesNow();
                    if (v == true) {
                      NotificationService.sendPushNotificationToStudents("Dinner Time", "Mess Open");
                    }
                    if (v == false) {
                      _closeMessAndMarkAbsent('d');
                    }
                  },
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.poll, color: brandDark),
              title: const Text(
                'Create New Poll',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCreatePollDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.fact_check, color: brandDark),
              title: const Text(
                'Attendance Sheet',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAttendanceScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: brandDark),
              title: const Text(
                'View All Register Student',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminRegisteredStudentsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.set_meal, color: brandDark),
              title: const Text(
                'Set Menu (Today)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSetMenuDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar, color: brandDark),
              title: const Text(
                'Edit Weekly Timetable',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (context) => const WeeklyMenuEditorWidget());
              },
            ),
            Builder(
              builder: (context) {
                int unread = globalComplaints
                    .where(
                      (c) =>
                          c.date.isAfter(globalAdminLastViewedComplaints) &&
                          !globalAdminHiddenComplaints.contains(c.id),
                    )
                    .length;
                return ListTile(
                  leading: const Icon(
                    Icons.report_problem_outlined,
                    color: brandDark,
                  ),
                  title: Row(
                    children: [
                      const Text(
                        'View Student Complaints',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      globalAdminLastViewedComplaints = DateTime.now();
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminComplaintsScreen(
                          hidden: globalAdminHiddenComplaints,
                          onDelete: (id) async {
                            await SyncService.deleteComplaint(id);
                          },
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                );
              },
            ),
            const Divider(),

            ListTile(

              leading: const Icon(Icons.info_outline, color: brandDark),

              title: const Text(

                'About Developers',

                style: TextStyle(fontWeight: FontWeight.w600),

              ),

              onTap: () {

                Navigator.pop(context);

                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDevelopersScreen()));

              },

            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.people_alt, color: brandDark),
              title: const Text(
                'Manage Students',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStudentsScreen()));
              },
            ),

            ListTile(

              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'LogOut',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _onLogout,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Responsive Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        widget.photoUrl!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Admin Portal",
                        style: TextStyle(
                          color: brandGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: brandDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3, overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Body Content
          Expanded(
            child: _selectedIndex == 0
                ? _buildAdminHomeTab()
                : _selectedIndex == 1
                ? _buildNoticeTab()
                : _selectedIndex == 2 ? const ViewMenuTab() : _buildAdminsTab(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: brandOrange,
        unselectedItemColor: brandGray,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notice",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: "Menu",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: "Admins",
          ),
        ],
      ),
        ),
        if (_isFetchingData)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class StudentComplaintsScreen extends StatefulWidget {
  final String name;
  final String roomNo;
  final String? photoUrl;
  const StudentComplaintsScreen({
    super.key,
    required this.name,
    required this.roomNo,
    required this.photoUrl,
  });
  @override
  State<StudentComplaintsScreen> createState() =>
      _StudentComplaintsScreenState();
}

class _StudentComplaintsScreenState extends State<StudentComplaintsScreen> {
  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String? localComplaintImageUrl;
    bool isUploading = false;
    final ImagePicker _picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateSB) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "New Complaint",
            style: TextStyle(color: brandDark, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: "Title",
                  filled: true,
                  fillColor: brandInputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Description",
                  filled: true,
                  fillColor: brandInputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 40,
                        maxWidth: 800,
                      );
                      if (image != null) {
                        setStateSB(() { isUploading = true; });
                        final bytes = await image.readAsBytes();
                        final url = await SyncService.uploadImage(bytes);
                        setStateSB(() {
                          isUploading = false;
                          if (url != null) {
                            localComplaintImageUrl = url;
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.photo),
                    label: Text(isUploading ? "Uploading..." : "Attach Photo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandInputBg,
                      foregroundColor: brandDark,
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (localComplaintImageUrl != null)
                    const Icon(Icons.check_circle, color: Colors.green)
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: brandGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                  setState(() {
                    globalComplaints.insert(
                      0,
                      ComplaintItem(
                        DateTime.now().toString(),
                        titleCtrl.text,
                        msgCtrl.text,
                        DateTime.now(),
                        widget.name,
                        widget.roomNo,
                        widget.photoUrl,
                        localComplaintImageUrl,
                      ),
                    );
                  });
                  await SyncService.pushComplaints();
                  NotificationService.sendPushNotificationToAdmins(
                    "New Complaint: ${titleCtrl.text}",
                    "${widget.name} (${widget.roomNo}) has submitted a complaint."
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        title: const Text("Mess Complaints"),
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: globalSyncTrigger,
        builder: (context, _, __) {
          final myComplaints = globalComplaints
              .where(
                (c) =>
                    c.studentName == widget.name &&
                    !globalStudentHiddenComplaints.contains(c.id),
              )
              .toList();
          return myComplaints.isEmpty
              ? const Center(
                  child: Text(
                    "No complaints yet.",
                    style: TextStyle(color: brandGray),
                  ),
                )
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myComplaints.length,
              itemBuilder: (context, index) {
                final c = myComplaints[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      c.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                      subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          c.description,
                          style: const TextStyle(color: brandGray),
                        ),
                        if (c.complaintImageUrl != null && c.complaintImageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Image.network(
                            c.complaintImageUrl!,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: brandGray),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          formatDateTime(c.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: brandOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        setState(() => globalStudentHiddenComplaints.add(c.id));
                        saveStudentHiddenComplaints();
                      },
                    ),
                  ),
                );
              },
            );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: brandOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class AdminComplaintsScreen extends StatefulWidget {
  final Set<String> hidden;
  final Function(String) onDelete;
  const AdminComplaintsScreen({
    super.key,
    required this.hidden,
    required this.onDelete,
  });
  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  @override
  Widget build(BuildContext context) {
    final visible = globalComplaints
        .where((c) => !widget.hidden.contains(c.id))
        .toList();
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        title: const Text("Student Complaints"),
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: globalSyncTrigger,
        builder: (context, _, __) {
          final visible = globalComplaints
              .where((c) => !widget.hidden.contains(c.id))
              .toList();
          return visible.isEmpty
              ? const Center(
                  child: Text(
                    "No complaints yet.",
                    style: TextStyle(color: brandGray),
                  ),
                )
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final c = visible[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      child: (c.studentPhotoUrl != null && c.studentPhotoUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        c.studentPhotoUrl!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      c.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          c.description,
                          style: const TextStyle(color: brandDark),
                        ),
                        if (c.complaintImageUrl != null && c.complaintImageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Image.network(
                            c.complaintImageUrl!,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: brandGray),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          "By: ${c.studentName} (Room ${c.studentRoom})",
                          style: const TextStyle(
                            color: brandGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDateTime(c.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: brandOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        widget.onDelete(c.id);
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            );
        },
      ),
    );
  }
}

class AdminRegisteredStudentsScreen extends StatelessWidget {
  const AdminRegisteredStudentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        title: const Text("Registered Students"),
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
      ),
      body: globalRegisteredStudents.isEmpty
          ? const Center(
              child: Text(
                "No students registered yet.",
                style: TextStyle(color: brandGray),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: globalRegisteredStudents.length,
              itemBuilder: (context, index) {
                final s = globalRegisteredStudents[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: brandOrange,
                      child: (s.photoUrl != null && s.photoUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        s.photoUrl!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
                      radius: 24,
                      
                    ),
                    title: Text(
                      s.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                    subtitle: Text(
                      "Room: ${s.roomNo}",
                      style: const TextStyle(color: brandGray),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SwipeToConfirm extends StatefulWidget {
  final VoidCallback onConfirm;
  final String text;
  const SwipeToConfirm({
    super.key,
    required this.onConfirm,
    required this.text,
  });

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  final double _height = 60.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - _height;
        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: brandInputBg,
            borderRadius: BorderRadius.circular(_height / 2),
            border: Border.all(color: brandOrange.withOpacity(0.5)),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: brandGray,
                  ),
                ),
              ),
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                    });
                  },
                  onPanEnd: (details) {
                    if (_isConfirmed) return;
                    if (_dragPosition > maxDrag * 0.8) {
                      setState(() {
                        _dragPosition = maxDrag;
                        _isConfirmed = true;
                      });
                      widget.onConfirm();
                    } else {
                      setState(() {
                        _dragPosition = 0; // snap back
                      });
                    }
                  },
                  child: Container(
                    width: _height,
                    height: _height,
                    decoration: const BoxDecoration(
                      color: brandOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MealPassScreen extends StatefulWidget {
  final String mealName;
  final String? photoUrl;
  final String name;
  final String roomNo;
  const MealPassScreen({
    super.key,
    required this.mealName,
    required this.photoUrl,
    required this.name,
    required this.roomNo,
  });
  @override
  State<MealPassScreen> createState() => _MealPassScreenState();
}

class _MealPassScreenState extends State<MealPassScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    int hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12;
    return "${pad(dt.day)}/${pad(dt.month)}/${dt.year} | ${pad(hour12)}:${pad(dt.minute)}:${pad(dt.second)} $period";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade600,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 100),
            const SizedBox(height: 16),
            Text(
              "${widget.mealName.toUpperCase()} APPROVED",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: CircleAvatar(
                radius: 60,
                child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        widget.photoUrl!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Room: ${widget.roomNo}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _formatTime(_now),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});
  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  bool _isFetchingData = false;
  @override
  void initState() {
    super.initState();
    globalSyncTrigger.addListener(_onSync);
  }

  @override
  void dispose() {
    globalSyncTrigger.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  // --- TEMPORARY EDITING BLOCK START ---
  bool isEditingEnabled = false;
  static const String _editPassword = "asdfg lkjh zxcvb mn";
  Widget _buildExportRow({
    required VoidCallback onExcel,
    required VoidCallback onPdf,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Export:",
            style: TextStyle(fontWeight: FontWeight.bold, color: brandDark, fontSize: 13),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onExcel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
              child: const Row(
                children: [
                  Icon(Icons.table_chart, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text("Excel", style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onPdf,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
              child: const Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text("PDF", style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateYearlyStats(
    RegisteredStudent student,
    int year,
  ) {
    List<Map<String, dynamic>> yearly = [];
    List<String> monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    for (int m = 1; m <= 12; m++) {
      int p = 0;
      int a = 0;
      int actual = 0;
      int daysInMonth = DateUtils.getDaysInMonth(year, m);
      bool hasData = false;
      for (int d = 1; d <= daysInMonth; d++) {
        String key = "$year-$m-${d}_${student.roomNo}_${student.name}";
        var rec = getAttendanceMerged(key);
        if (rec != null) {
          hasData = true;
          bool isP = rec.l == 'P' || rec.d == 'P';
          if (isP)
            p++;
          else
            a++;
          if (rec.l == 'P') actual += 70;
          if (rec.d == 'P') actual += 70;
        }
      }
      if (hasData) {
        int payable = (p == 0 && a == 0) ? 0 : calculatePayableBill(actual ~/ 70);
        String pKey = "$year-${m}_${student.roomNo}_${student.name}";
        int paid = globalMonthlyPaid[pKey] ?? 0;
        yearly.add({
          'month': monthNames[m],
          'p': p,
          'a': a,
          'actual': actual,
          'payable': payable,
          'paid': paid,
          'due': payable - paid,
        });
      }
    }
    return yearly;
  }

  void _promptEditPassword() {
    final TextEditingController passCtrl = TextEditingController();
    bool isObscured = true;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: brandOrange),
                  SizedBox(width: 8),
                  Text(
                    "Security Verification",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: brandDark,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Enter the 20-digit password to enable editing mode:",
                    style: TextStyle(fontSize: 13, color: brandGray),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: isObscured,
                    keyboardType: TextInputType.number,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: "20-Digit Password",
                      errorText: errorText,
                      filled: true,
                      fillColor: brandInputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility_off : Icons.visibility,
                          color: brandGray,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isObscured = !isObscured;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: brandGray),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (passCtrl.text.trim() == _editPassword) {
                      Navigator.pop(ctx);
                      setState(() {
                        isEditingEnabled = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Editing mode enabled successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      setDialogState(() {
                        errorText = "Incorrect password! Access denied.";
                      });
                    }
                  },
                  child: const Text(
                    "Verify",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _promptResetPassword() {
    final TextEditingController passCtrl = TextEditingController();
    bool isObscured = true;
    String? errorText;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Factory Reset Data", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("WARNING: This will wipe all students, attendance, complaints, and notices! Enter the master password to proceed:", style: TextStyle(fontSize: 13, color: brandGray)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: isObscured,
                    decoration: InputDecoration(
                      labelText: "Master Password",
                      errorText: errorText,
                      filled: true,
                      fillColor: brandInputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: brandGray),
                        onPressed: () => setDialogState(() => isObscured = !isObscured),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: brandGray)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (hashPassword(passCtrl.text) == "f0ff3b50086e347379ef2f8dbc1227a6949e6cd03123c03ef3f3f7adc8da96be") {
                      Navigator.pop(ctx);
                      await _performReset();
                    } else {
                      setDialogState(() => errorText = "Incorrect password!");
                    }
                  },
                  child: const Text("WIPE DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performReset() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final dbRef = FirebaseDatabase.instance.ref('hostelData');
      await dbRef.child('students').remove();
      await dbRef.child('attendance').remove();
      await dbRef.child('paid').remove();
      await dbRef.child('polls').remove();
      
      final supa = Supabase.instance.client;
      await supa.from('notices').delete().not('id', 'is', null);
      await supa.from('complaints').delete().not('id', 'is', null);
      
      globalRegisteredStudents.clear();
      
      globalAttendanceMap.clear();
      globalMonthlyPaid.clear();
      globalNotices.clear();
      globalComplaints.clear();
      SyncService.dynamicPolls.clear();
      
      await SyncService.pushStudents();
      await dbRef.child('force_logout').set(DateTime.now().millisecondsSinceEpoch);
      globalSyncTrigger.value++;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userType');
      await prefs.remove('identifier');
      await prefs.remove('photoPath');
      await prefs.remove('extraInfo');
      await prefs.remove('last_student_name');
      await prefs.remove('last_student_room');
      await prefs.remove('last_student_photo');
      await prefs.remove('last_admin_phone');
      await prefs.remove('last_admin_name');
      await prefs.remove('last_admin_photo');
      
      Navigator.pop(context); // close loading
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All data has been reset!"), backgroundColor: Colors.green));
    } catch(e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
    }
  }

  // --- TEMPORARY EDITING BLOCK END ---
  DateTime _selectedDailyDate = DateTime.now();
  String _dailySearchQuery = "";

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _monthlySearchQuery = "";
  String _paymentFilter = "All"; // All, Paid, Unpaid, Half Paid

  int _getDaysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

  // ===== DAILY VIEW LOGIC =====
  List<Map<String, dynamic>> _generateDailyRows() {
    List<Map<String, dynamic>> rows = [];
    String dateStr =
        "${_selectedDailyDate.year}-${_selectedDailyDate.month}-${_selectedDailyDate.day}";
    for (int roomInt = 101; roomInt <= 120; roomInt++) {
      _addDailyRoomSlots(rows, roomInt.toString(), dateStr);
    }
    for (int roomInt = 201; roomInt <= 220; roomInt++) {
      _addDailyRoomSlots(rows, roomInt.toString(), dateStr);
    }
    if (_dailySearchQuery.isNotEmpty) {
      String q = _dailySearchQuery.toLowerCase();
      rows = rows
          .where(
            (r) =>
                r['room'].toLowerCase().contains(q) ||
                r['name'].toLowerCase().contains(q),
          )
          .toList();
    }
    return rows;
  }

  void _addDailyRoomSlots(
    List<Map<String, dynamic>> rows,
    String room,
    String dateStr,
  ) {
    var roomStudents = globalRegisteredStudents
        .where((s) => s.roomNo == room)
        .toList();
    for (int i = 0; i < 4; i++) {
      if (i < roomStudents.length) {
        String name = roomStudents[i].name;
        String key = "${dateStr}_${room}_$name";
        DailyRecord? rec = getAttendanceMerged(key);
        int total = 0;
        if (rec != null) {
          if (rec.l == 'P') total += 70;
          if (rec.d == 'P') total += 70;
        }
        rows.add({
          'room': room,
          'name': name,
          'isEmpty': false,
          'hasAttendance': rec != null,

          'l': rec?.l ?? '-',
          'd': rec?.d ?? '-',
          'total': total,
        });
      } else {
        rows.add({
          'room': room,
          'name': 'Empty Slot',
          'isEmpty': true,
          'hasAttendance': false,
          'l': '-',
          'd': '-',
          'total': 0,
        });
      }
    }
  }

  Widget _buildDailyView() {
    final rows = _generateDailyRows();
    String dateStr =
        "${_selectedDailyDate.day.toString().padLeft(2, '0')}/${_selectedDailyDate.month.toString().padLeft(2, '0')}/${_selectedDailyDate.year}";

    void export(String format) {
      List<String> h = ["Room", "Student Name", "Lunch", "Dinner", "Total"];
      List<List<String>> d = _generateDailyRows()
          .map(
            (r) => [
              r['room'].toString(),
              r['name'].toString(),
              r['l'].toString(),
              r['d'].toString(),
              r['total'].toString(),
            ],
          )
          .toList();
      String dateStr =
          "${_selectedDailyDate.day}-${_selectedDailyDate.month}-${_selectedDailyDate.year}";
      ExportService.exportReport(
        context: context,
        title: "Daily Attendance - $dateStr",
        headers: h,
        data: d,
        format: format,
      );
    }

    return Column(
      children: [
        _buildExportRow(
          onExcel: () => export('excel'),
          onPdf: () => export('pdf'),
          
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search Room or Name...",
                    prefixIcon: const Icon(Icons.search, color: brandGray),
                    filled: true,
                    fillColor: brandInputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _dailySearchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDailyDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _isFetchingData = true);
                    await fetchAttendanceMonth(picked.year, picked.month);
                    setState(() {
                      _selectedDailyDate = picked;
                      _isFetchingData = false;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                label: Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: brandDark,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  "Room",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  "Name",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                flex: 1,
                child: Text(
                  "L",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "D",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "Date",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "Total",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              Color bgColor = index % 2 == 0
                  ? Colors.white
                  : Colors.grey.shade50;
              bool showDivider = (index + 1) % 4 == 0;

              Widget buildCell(
                String text,
                String mealType,
                String dateStrFull,
                String room,
                String name,
                bool isEmpty,
              ) {
                Color textColor = brandGray;
                if (text == 'P')
                  textColor = Colors.green;
                else if (text == 'A')
                  textColor = Colors.redAccent;
                Widget textWidget = Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: text == 'P' || text == 'A'
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                );

                // --- TEMPORARY EDITING BLOCK START ---
                if (isEditingEnabled && !isEmpty) {
                  return InkWell(
                    onTap: () async {
                      String key =
                          "${_selectedDailyDate.year}-${_selectedDailyDate.month}-${_selectedDailyDate.day}_${room}_${name}";
                      DailyRecord rec =
                          globalAttendanceMap[key] ?? DailyRecord();
                      setState(() {
                        if (mealType == 'L') {
                          rec.l = (rec.l == 'P') ? 'A' : 'P';
                        } else {
                          rec.d = (rec.d == 'P') ? 'A' : 'P';
                        }
                        globalAttendanceMap[key] = rec;
                      });
                      await SyncService.pushAttendance(key, rec);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.blue.withOpacity(0.1),
                      child: textWidget,
                    ),
                  );
                }
                // --- TEMPORARY EDITING BLOCK END ---
                return textWidget;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: showDivider
                      ? const Border(
                          bottom: BorderSide(color: Colors.black12, width: 2),
                        )
                      : null,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        row['room'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: row['isEmpty'] ? Colors.grey : brandDark,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        row['name'],
                        style: TextStyle(
                          color: row['isEmpty'] ? Colors.grey : brandDark,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3, overflow: TextOverflow.visible,
                      ),
                    ),

                    Expanded(
                      flex: 1,
                      child: buildCell(
                        row['l'],
                        'L',
                        dateStr,
                        row['room'],
                        row['name'],
                        row['isEmpty'],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildCell(
                        row['d'],
                        'D',
                        dateStr,
                        row['room'],
                        row['name'],
                        row['isEmpty'],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        row['hasAttendance'] ? dateStr : '',
                        style: const TextStyle(
                          color: brandGray,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        row['hasAttendance']
                            ? "₹${row['total']}"
                            : (row['isEmpty'] ? '' : '-'),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: row['total'] > 0 ? brandOrange : brandGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===== MONTHLY VIEW LOGIC =====
  List<Map<String, dynamic>> _generateMonthlyRows() {
    List<Map<String, dynamic>> rows = [];
    int daysInMonth = _getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    for (var student in globalRegisteredStudents) {
      String monthKey =
          "${_selectedMonth.year}-${_selectedMonth.month}_${student.roomNo}_${student.name}";

      int present = 0;
      int absent = 0;
      int actual = 0;

      for (int d = 1; d <= daysInMonth; d++) {
        String dayKey =
            "${_selectedMonth.year}-${_selectedMonth.month}-${d}_${student.roomNo}_${student.name}";
        var rec = getAttendanceMerged(dayKey);
        if (rec != null) {
          bool isP = rec.l == 'P' || rec.d == 'P';
          if (isP)
            present++;
          else
            absent++;

          if (rec.l == 'P') actual += 70;
          if (rec.d == 'P') actual += 70;
        }
      }

      int payable = 0;
      if (present == 0 && absent == 0) {
        payable = 0;
      } else {
        payable = calculatePayableBill(actual ~/ 70);
      }

      int paidAmt = globalMonthlyPaid[monthKey] ?? 0;
      String pStatus = 'Paid';
      if (payable == 0)
        pStatus = 'Paid';
      else if (paidAmt == 0)
        pStatus = 'Unpaid';
      else if (paidAmt < payable)
        pStatus = 'Half Paid';

      if (_paymentFilter != 'All' && _paymentFilter != pStatus) continue;

      if (_monthlySearchQuery.isNotEmpty) {
        String q = _monthlySearchQuery.toLowerCase();
        if (!student.roomNo.toLowerCase().contains(q) &&
            !student.name.toLowerCase().contains(q))
          continue;
      }

      rows.add({
        'paid': paidAmt,
        'student': student,
        'present': present,
        'absent': absent,
        'actual': actual,
        'payable': payable,
        'status': pStatus,
        'monthKey': monthKey,
      });
    }

    // Sort by Room No
    rows.sort(
      (a, b) => (a['student'] as RegisteredStudent).roomNo.compareTo(
        (b['student'] as RegisteredStudent).roomNo,
      ),
    );
    return rows;
  }

  void _showStudentHistoryDialog(
    RegisteredStudent student,
    Map<String, dynamic> rowData,
  ) {
    int daysInMonth = _getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // --- TEMPORARY EDITING BLOCK START ---
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            List<Map<String, dynamic>> history = [];
            int currentActual = 0;
            int currentPresent = 0;
            int currentAbsent = 0;

            for (int d = 1; d <= daysInMonth; d++) {
              String dayKey =
                  "${_selectedMonth.year}-${_selectedMonth.month}-${d}_${student.roomNo}_${student.name}";
              var rec = getAttendanceMerged(dayKey);

              if (rec != null || isEditingEnabled) {
                int dailyTotal = 0;
                if (rec != null && rec.l == 'P') dailyTotal += 70;
                if (rec != null && rec.d == 'P') dailyTotal += 70;

                if (rec != null) {
                  bool isP = rec.l == 'P' || rec.d == 'P';
                  if (isP)
                    currentPresent++;
                  else
                    currentAbsent++;
                  if (rec.l == 'P') currentActual += 70;
                  if (rec.d == 'P') currentActual += 70;
                }

                history.add({
                  'day': d,
                  'l': rec?.l ?? '-',
                  'd': rec?.d ?? '-',
                  'total': dailyTotal,
                });
              }
            }

            int currentPayable = 0;
            if (currentPresent == 0 && currentAbsent == 0) {
              currentPayable = 0;
            } else {
              currentPayable = calculatePayableBill(currentActual ~/ 70);
            }
            // --- TEMPORARY EDITING BLOCK END ---
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${student.name} (Room ${student.roomNo})",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: brandDark,
                                ),
                                maxLines: 3, overflow: TextOverflow.visible,
                              ),
                              // --- TEMPORARY EDITING BLOCK START ---
                              Text(
                                "Month: ${_selectedMonth.month}/${_selectedMonth.year} | Payable: ₹$currentPayable",
                                style: const TextStyle(
                                  color: brandOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // --- TEMPORARY EDITING BLOCK END ---
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: brandDark,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Date",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            "L",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            "D",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Total",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: history.isEmpty
                        ? const Center(
                            child: Text(
                              "No attendance records found for this month.",
                            ),
                          )
                        : ListView.builder(
                            itemCount: history.length,
                            itemBuilder: (context, idx) {
                              var h = history[idx];
                              Widget buildCell(String text, String mealType) {
                                Color c = brandGray;
                                if (text == 'P') c = Colors.green;
                                if (text == 'A') c = Colors.redAccent;
                                Widget textWidget = Text(
                                  text,
                                  style: TextStyle(
                                    color: c,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                                // --- TEMPORARY EDITING BLOCK START ---
                                if (isEditingEnabled) {
                                  return InkWell(
                                    onTap: () {
                                      setModalState(() async {
                                        String key =
                                            "${_selectedMonth.year}-${_selectedMonth.month}-${h['day']}_${student.roomNo}_${student.name}";
                                        DailyRecord rec =
                                            globalAttendanceMap[key] ??
                                            DailyRecord();
                                        if (mealType == 'L') {
                                          rec.l = (rec.l == 'P') ? 'A' : 'P';
                                        } else {
                                          rec.d = (rec.d == 'P') ? 'A' : 'P';
                                        }
                                        globalAttendanceMap[key] = rec;
                                        await SyncService.pushAttendance(key, rec);

                                        setState(
                                          () {},
                                        ); // trigger rebuild on parent for instant UI update
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      color: Colors.blue.withOpacity(0.1),
                                      child: textWidget,
                                    ),
                                  );
                                }
                                // --- TEMPORARY EDITING BLOCK END ---
                                return textWidget;
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.black12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${h['day'].toString().padLeft(2, '0')}/${_selectedMonth.month.toString().padLeft(2, '0')}",
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: buildCell(h['l'], 'L'),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: buildCell(h['d'], 'D'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "₹${h['total']}",
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: brandDark,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text(
                            "Export Month:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          _buildExportRow(
                            onExcel: () {
                              List<String> h = [
                                "Date",
                                "Lunch",
                                "Dinner",
                                "Total",
                              ];
                              List<List<String>> d = history
                                  .map(
                                    (hi) => [
                                      "${hi['day']}/${_selectedMonth.month}",
                                      hi['l'].toString(),
                                      hi['d'].toString(),
                                      hi['total'].toString(),
                                    ],
                                  )
                                  .toList();
                              ExportService.exportReport(
                                context: context,
                                title:
                                    "${student.name} - ${_selectedMonth.month}-${_selectedMonth.year}",
                                headers: h,
                                data: d,
                                format: 'excel',
                              );
                            },
                            onPdf: () {
                              List<String> h = [
                                "Date",
                                "Lunch",
                                "Dinner",
                                "Total",
                              ];
                              List<List<String>> d = history
                                  .map(
                                    (hi) => [
                                      "${hi['day']}/${_selectedMonth.month}",
                                      hi['l'].toString(),
                                      hi['d'].toString(),
                                      hi['total'].toString(),
                                    ],
                                  )
                                  .toList();
                              ExportService.exportReport(
                                context: context,
                                title:
                                    "${student.name} - ${_selectedMonth.month}-${_selectedMonth.year}",
                                headers: h,
                                data: d,
                                format: 'pdf',
                              );
                            },
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            "Export Year:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          _buildExportRow(
                            onExcel: () {
                              List<String> h = [
                                "Month",
                                "Present",
                                "Absent",
                                "Actual",
                                "Payable",
                                "Paid",
                                "Due",
                              ];
                              List<List<String>> d = [];
                              for (int m = 1; m <= 12; m++) {
                                String key = "${_selectedMonth.year}-${m}_${student.roomNo}_${student.name}";
                                int paid = globalMonthlyPaid[key] ?? 0;
                                int p = 0;
                                int a = 0;
                                for (int day = 1; day <= 31; day++) {
                                  String dKey = "${_selectedMonth.year}-${m}-${day}_${student.roomNo}_${student.name}";
                                  DailyRecord? rec = getAttendanceMerged(dKey);
                                  if (rec != null) {
                                    if (rec.l == "P") p++;
                                    else if (rec.l == "A") a++;
                                    if (rec.d == "P") p++;
                                    else if (rec.d == "A") a++;
                                  }
                                }
                                int actual = p * 70;
                                int payable = (p == 0 && a == 0) ? 0 : calculatePayableBill(p);
                                int due = payable - paid;
                                if (p > 0 || a > 0 || paid > 0) {
                                  d.add([m.toString(), p.toString(), a.toString(), actual.toString(), payable.toString(), paid.toString(), due.toString()]);
                                }
                              }
                              ExportService.exportReport(
                                context: context,
                                title: "${student.name} - Yearly ${_selectedMonth.year}",
                                headers: h,
                                data: d,
                                format: "excel",
                              );
                            },
                            onPdf: () {
                              List<String> h = [
                                "Month",
                                "Present",
                                "Absent",
                                "Actual",
                                "Payable",
                                "Paid",
                                "Due",
                              ];
                              List<List<String>> d = [];
                              for (int m = 1; m <= 12; m++) {
                                String key = "${_selectedMonth.year}-${m}_${student.roomNo}_${student.name}";
                                int paid = globalMonthlyPaid[key] ?? 0;
                                int p = 0;
                                int a = 0;
                                for (int day = 1; day <= 31; day++) {
                                  String dKey = "${_selectedMonth.year}-${m}-${day}_${student.roomNo}_${student.name}";
                                  DailyRecord? rec = getAttendanceMerged(dKey);
                                  if (rec != null) {
                                    if (rec.l == "P") p++;
                                    else if (rec.l == "A") a++;
                                    if (rec.d == "P") p++;
                                    else if (rec.d == "A") a++;
                                  }
                                }
                                int actual = p * 70;
                                int payable = (p == 0 && a == 0) ? 0 : calculatePayableBill(p);
                                int due = payable - paid;
                                if (p > 0 || a > 0 || paid > 0) {
                                  d.add([m.toString(), p.toString(), a.toString(), actual.toString(), payable.toString(), paid.toString(), due.toString()]);
                                }
                              }
                              ExportService.exportReport(
                                context: context,
                                title: "${student.name} - Yearly ${_selectedMonth.year}",
                                headers: h,
                                data: d,
                                format: "pdf",
                              );
                            }
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
                            
  Widget _buildMonthlyView() {
    final rows = _generateMonthlyRows();
    List<String> monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String monthStr =
        "${monthNames[_selectedMonth.month]} ${_selectedMonth.year}";

    void export(String format) {
      List<String> h = [
        "Room",
        "Student Name",
        "P",
        "A",
        "Actual",
        "Payable",
        "Paid",
        "Due",
        "Status",
      ];
      List<List<String>> d = _generateMonthlyRows()
          .map(
            (r) => [
              (r['student'] as RegisteredStudent).roomNo,
              (r['student'] as RegisteredStudent).name,
              r['present'].toString(),
              r['absent'].toString(),
              r['actual'].toString(),
              r['payable'].toString(),
              r['paid'].toString(),
              (r['payable'] - r['paid']).toString(),
              r['status'].toString(),
            ],
          )
          .toList();
      List<String> monthNames = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      String monthStr =
          "${monthNames[_selectedMonth.month]} ${_selectedMonth.year}";
      ExportService.exportReport(
        context: context,
        title: "Monthly Attendance - $monthStr",
        headers: h,
        data: d,
        format: format,
      );
    }

    return Column(
      children: [
        _buildExportRow(
          onExcel: () => export('excel'),
          onPdf: () => export('pdf'),
          
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search, color: brandGray),
                        filled: true,
                        fillColor: brandInputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => _monthlySearchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: brandInputBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _paymentFilter,
                          items: ['All', 'Paid', 'Half Paid', 'Unpaid']
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _paymentFilter = val!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: brandDark),
                    onPressed: () async {
                      DateTime newMonth = DateTime(
                        _selectedMonth.month == 1
                            ? _selectedMonth.year - 1
                            : _selectedMonth.year,
                        _selectedMonth.month == 1
                            ? 12
                            : _selectedMonth.month - 1,
                      );
                      setState(() => _isFetchingData = true);
                      await fetchAttendanceMonth(newMonth.year, newMonth.month);
                      setState(() {
                        _selectedMonth = newMonth;
                        _isFetchingData = false;
                      });
                    },
                  ),
                  Text(
                    monthStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: brandDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: brandDark),
                    onPressed: () async {
                      DateTime newMonth = DateTime(
                        _selectedMonth.month == 12
                            ? _selectedMonth.year + 1
                            : _selectedMonth.year,
                        _selectedMonth.month == 12
                            ? 1
                            : _selectedMonth.month + 1,
                      );
                      setState(() => _isFetchingData = true);
                      await fetchAttendanceMonth(newMonth.year, newMonth.month);
                      setState(() {
                        _selectedMonth = newMonth;
                        _isFetchingData = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          color: brandDark,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  "Student",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "P",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "A",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "Actual",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "Payable",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "Paid",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "Due",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              RegisteredStudent student = row['student'];
              Color bgColor = index % 2 == 0
                  ? Colors.white
                  : Colors.grey.shade50;

              Color statusColor = Colors.redAccent;
              if (row['status'] == 'Paid') statusColor = Colors.green;
              if (row['status'] == 'Half Paid') statusColor = Colors.orange;

              return InkWell(
                onTap: () => _showStudentHistoryDialog(student, row),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: const Border(
                      bottom: BorderSide(color: Colors.black12),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: brandDark,
                              ),
                              maxLines: 3, overflow: TextOverflow.visible,
                            ),
                            Text(
                              "Rm: ${student.roomNo}",
                              style: const TextStyle(
                                color: brandGray,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "${row['present']}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "${row['absent']}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "₹${row['actual']}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: brandDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "₹${row['payable']}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: brandOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.center,
                          child: InkWell(
                            onTap: () {
                              TextEditingController amtCtrl =
                                  TextEditingController(
                                    text: row['paid'].toString(),
                                  );
                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog(
                                    title: const Text("Update Payment"),
                                    content: TextField(
                                      controller: amtCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: "Paid Amount (₹)",
                                        filled: true,
                                        fillColor: brandInputBg,
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          int? val = int.tryParse(amtCtrl.text);
                                          if (val != null) {
                                            setState(() {
                                              globalMonthlyPaid[row['monthKey']] =
                                                  val;
                                            });
                                            await SyncService.pushPaid();
                                          }
                                          Navigator.pop(ctx);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: brandDark,
                                        ),
                                        child: const Text(
                                          "Save",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: brandInputBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "₹${row['paid']}",
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "₹${row['payable'] - row['paid']}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: brandBg,
            appBar: AppBar(
              backgroundColor: brandOrange,
              title: const Text(
                "Attendance Sheet",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              // --- TEMPORARY EDITING BLOCK START ---
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  tooltip: "Factory Reset Data",
                  onPressed: _promptResetPassword,
                ),
                Row(
                  children: [
                    const Text(
                      "Enable Edit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: isEditingEnabled,
                      activeColor: Colors.white,
                      onChanged: (val) {
                        if (val) {
                          // Force rebuild so switch visually snaps back to OFF immediately
                          setState(() {
                            isEditingEnabled = false;
                          });
                          _promptEditPassword();
                        } else {
                          setState(() {
                            isEditingEnabled = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Editing mode disabled."),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
              // --- TEMPORARY EDITING BLOCK END ---
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: "Daily View"),
                  Tab(text: "Monthly View"),
                ],
              ),
            ),
            body: TabBarView(children: [_buildDailyView(), _buildMonthlyView()]),
          ),
        ),
        if (_isFetchingData)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class StudentAttendanceScreen extends StatefulWidget {
  final String name;
  final String roomNo;
  const StudentAttendanceScreen({
    super.key,
    required this.name,
    required this.roomNo,
  });

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    String suffix = "_${widget.roomNo}_${widget.name}";
    Set<String> allKeys = {...globalAttendanceMap.keys, ...globalApiAttendanceMap.keys};
    List<String> myKeys = allKeys
        .where((k) => k.endsWith(suffix))
        .toList();

    List<Map<String, dynamic>> records = [];
    for (String key in myKeys) {
      String datePart = key.split('_')[0];
      List<String> parts = datePart.split('-');
      int y = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      int d = int.parse(parts[2]);
      DateTime dt = DateTime(y, m, d);

      if (selectedDate != null) {
        if (dt.year != selectedDate!.year ||
            dt.month != selectedDate!.month ||
            dt.day != selectedDate!.day) {
          continue;
        }
      }

      DailyRecord rec = getAttendanceMerged(key)!;
      int total = 0;
      if (rec.l == 'P') total += 70;
      if (rec.d == 'P') total += 70;

      records.add({
        'dateObj': dt,
        'dateStr':
            "${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}/$y",

        'l': rec.l,
        'd': rec.d,
        'total': total,
      });
    }

    records.sort(
      (a, b) => (b['dateObj'] as DateTime).compareTo(a['dateObj'] as DateTime),
    );

    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: const Text(
          "My Attendance",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => selectedDate = null),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: brandDark,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "Room",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Name",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Text(
                    "L",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "D",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Date",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Total",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (records.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  "No attendance records found.",
                  style: TextStyle(color: brandGray),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final row = records[index];
                  Color bgColor = index % 2 == 0
                      ? Colors.white
                      : Colors.grey.shade50;

                  Widget buildCell(String text) {
                    Color textColor = brandGray;
                    if (text == 'P')
                      textColor = Colors.green;
                    else if (text == 'A')
                      textColor = Colors.redAccent;
                    return Text(
                      text,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: text == 'P' || text == 'A'
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    );
                  }

                  return Container(
                    color: bgColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            widget.roomNo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: brandDark,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            widget.name,
                            style: const TextStyle(
                              color: brandDark,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 3, overflow: TextOverflow.visible,
                          ),
                        ),

                        Expanded(flex: 1, child: buildCell(row['l'])),
                        Expanded(flex: 1, child: buildCell(row['d'])),
                        Expanded(
                          flex: 3,
                          child: Text(
                            row['dateStr'],
                            style: const TextStyle(
                              color: brandGray,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "₹${row['total']}",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: row['total'] > 0 ? brandOrange : brandGray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

























class UpdateCheckerWrapper extends StatefulWidget {
  final Widget child;
  const UpdateCheckerWrapper({super.key, required this.child});

  @override
  State<UpdateCheckerWrapper> createState() => _UpdateCheckerWrapperState();
}

class _UpdateCheckerWrapperState extends State<UpdateCheckerWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


class AboutDevelopersScreen extends StatelessWidget {
  const AboutDevelopersScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep slate background
      appBar: AppBar(
        title: const Text("About Developers", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Image
            Image.asset('assets/mdhk_logo.png', width: 300),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});
  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    globalSyncTrigger.addListener(_onSync);
  }
  
  @override
  void dispose() {
    globalSyncTrigger.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }
  
  void _showAddEditDialog({RegisteredStudent? student}) {
    final nameCtrl = TextEditingController(text: student?.name ?? '');
    final roomCtrl = TextEditingController(text: student?.roomNo ?? '');
     
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(student == null ? 'Add Student' : 'Edit Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room No')),
             
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || roomCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Room No are required')));
                return;
              }
              if (student == null) {
                globalRegisteredStudents.add(RegisteredStudent(nameCtrl.text, roomCtrl.text, null, ''));
              } else {
                int idx = globalRegisteredStudents.indexOf(student);
                if (idx != -1) {
                  globalRegisteredStudents[idx] = RegisteredStudent(nameCtrl.text, roomCtrl.text, student.photoUrl, student.pin, email: student.email);
                }
              }
              await SyncService.pushStudents();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<RegisteredStudent> filtered = globalRegisteredStudents.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.roomNo.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             s.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    
    // Sort by Room No then Name
    filtered.sort((a, b) {
      int rComp = (int.tryParse(a.roomNo) ?? 0).compareTo(int.tryParse(b.roomNo) ?? 0);
      if (rComp != 0) return rComp;
      return a.name.compareTo(b.name);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Students", style: TextStyle(color: Colors.white)),
        backgroundColor: brandOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by Room or Name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final s = filtered[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Room: ${s.roomNo} | PIN: ${s.pin == "" ? "Not Set" : "Set (Hidden)"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditDialog(student: s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dCtx) {
                                String deleteText = "";
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Delete ${s.name}?'),
                                          const SizedBox(height: 10),
                                          TextField(
                                            autofocus: true,
                                            onChanged: (val) {
                                              setState(() {
                                                deleteText = val;
                                              });
                                            },
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                                        TextButton(
                                          onPressed: deleteText == 'DELETE' ? () async {
                                            globalRegisteredStudents.remove(s);
                                            await SyncService.pushStudents();
                                            Navigator.pop(dCtx);
                                          } : null, 
                                          child: Text('Delete', style: TextStyle(color: deleteText == 'DELETE' ? Colors.red : Colors.grey)),
                                        ),
                                      ],
                                    );
                                  }
                                );
                              }
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: brandOrange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEditDialog(),
      ),
    );
  }
}


