import 'dart:io';
import 'dart:async';
import 'notification_service.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'export_service.dart';
import 'splash_screen.dart';
import 'package:flutter/services.dart'; // Added for inputFormatters
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart'; // For OTP/Email verification API calls
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const String RENDER_API_URL = "https://hostel-backend-pdph.onrender.com";
Map<String, DailyRecord> globalApiAttendanceMap = {};
Set<String> _fetchedApiMonths = {};
String? globalStudentSuffix;

Future<void> fetchAttendanceMonth(int year, int month) async {
  String monthKey = "${globalHostelMode}_$year-$month";
  if (_fetchedApiMonths.contains(monthKey)) return;
  try {
    final dio = Dio();
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.sendTimeout = const Duration(seconds: 10);
    final response = await dio.get(
      '$RENDER_API_URL/attendance-history?year=$year&month=$month&mode=$globalHostelMode',
    );
    if (response.data != null && response.data['success'] == true) {
      List data = response.data['data'];
      for (var item in data) {
        try {
          DateTime itemDate = DateTime.parse(item['attendance_date']).toLocal();
          String key =
              "${itemDate.year}-${itemDate.month}-${itemDate.day}_${item['room_no']}_${item['student_name']}";
          // POINT 1 FIX: If student logged in, only store this student's records to save memory/data
          if (globalStudentSuffix != null && !key.endsWith(globalStudentSuffix!)) {
            continue;
          }
          DailyRecord rec = DailyRecord();
          rec.l = item['lunch_status'] ?? '';
          rec.d = item['dinner_status'] ?? '';
          globalApiAttendanceMap[key] = rec;
        } catch (e) {}
      }
      _fetchedApiMonths.add(monthKey);
    }
  } catch (e) {
    print("API Error: $e");
  }
}

String attendanceSafeKey(String key) => key.replaceAll(RegExp(r'[.#$\[\]/]'), '_');

DailyRecord? getAttendanceMerged(String key) {
  String safeKey = attendanceSafeKey(key);
  DateTime now = realTime;
  String todayPrefix = "${now.year}-${now.month}-${now.day}_";
  if (safeKey.startsWith(todayPrefix) || key.startsWith(todayPrefix)) {
    return globalAttendanceMap[safeKey] ?? globalAttendanceMap[key];
  }
  return globalApiAttendanceMap[safeKey] ??
      globalApiAttendanceMap[key] ??
      globalAttendanceMap[safeKey] ??
      globalAttendanceMap[key];
}

void forEachMergedAttendance(
  void Function(String key, DailyRecord rec) action,
) {
  Set<String> processed = {};
  DateTime now = realTime;
  String todayPrefix = "${now.year}-${now.month}-${now.day}_";
  globalAttendanceMap.forEach((key, rec) {
    String safeK = attendanceSafeKey(key);
    if ((safeK.startsWith(todayPrefix) || key.startsWith(todayPrefix)) && !processed.contains(safeK)) {
      processed.add(safeK);
      action(safeK, rec);
    }
  });
  globalApiAttendanceMap.forEach((key, rec) {
    String safeK = attendanceSafeKey(key);
    if (!processed.contains(safeK)) {
      processed.add(safeK);
      action(safeK, rec);
    }
  });
  globalAttendanceMap.forEach((key, rec) {
    String safeK = attendanceSafeKey(key);
    if (!processed.contains(safeK)) {
      processed.add(safeK);
      action(safeK, rec);
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
  const months = [
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
  return months[month - 1];
}

String _getWeekdayName(int weekday) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return days[weekday - 1];
}

class WeeklyMenuEditorWidget extends StatefulWidget {
  const WeeklyMenuEditorWidget({super.key});
  @override
  _WeeklyMenuEditorWidgetState createState() => _WeeklyMenuEditorWidgetState();
}

class _WeeklyMenuEditorWidgetState extends State<WeeklyMenuEditorWidget> {
  int _selectedDay = realTime.weekday;
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
    setState(() => _isLoading = true); // Default fallback
    final fallback =
        defaultWeeklyMenu[_selectedDay] ?? defaultWeeklyMenu[DateTime.monday]!;
    String bf = fallback['breakfast']!;
    String lu = fallback['lunch']!;
    String dn = fallback['dinner']!;
    try {
      final snap = await FirebaseDatabase.instance
          .ref('hostelData_$globalHostelMode/weekly_template/$_selectedDay')
          .get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        if (data['breakfast'] != null &&
            data['breakfast'].toString().trim().isNotEmpty)
          bf = data['breakfast'];
        if (data['lunch'] != null && data['lunch'].toString().trim().isNotEmpty)
          lu = data['lunch'];
        if (data['dinner'] != null &&
            data['dinner'].toString().trim().isNotEmpty)
          dn = data['dinner'];
      }
    } catch (e) {}
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
      await FirebaseDatabase.instance
          .ref('hostelData_$globalHostelMode/weekly_template/$_selectedDay')
          .set({
            'breakfast': _bfCtrl.text.trim(),
            'lunch': _luCtrl.text.trim(),
            'dinner': _dnCtrl.text.trim(),
          });
      globalSyncTrigger.notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Menu for day $_selectedDay updated!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error updating menu"),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Edit Weekly Timetable",
        style: TextStyle(fontWeight: FontWeight.bold, color: brandDark),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: "Select Day",
                border: OutlineInputBorder(),
              ),
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
                  setState(() {
                    _selectedDay = val;
                  });
                  _loadDayMenu();
                }
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading) ...[
              TextField(
                controller: _bfCtrl,
                decoration: const InputDecoration(
                  labelText: "Breakfast",
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _luCtrl,
                decoration: const InputDecoration(
                  labelText: "Lunch",
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dnCtrl,
                decoration: const InputDecoration(
                  labelText: "Dinner",
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandGreen,
            foregroundColor: Colors.white,
          ),
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
    final defaultMenu =
        defaultWeeklyMenu[realTime.weekday] ??
        defaultWeeklyMenu[DateTime.monday]!;
    final now = realTime;
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final weekDay = now.weekday;
    return FutureBuilder<List<DataSnapshot>>(
      future: Future.wait([
        FirebaseDatabase.instance
            .ref('hostelData_$globalHostelMode/weekly_template/$weekDay')
            .get(),
        FirebaseDatabase.instance
            .ref('hostelData_$globalHostelMode/daily_menus/$todayStr')
            .get(),
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
            if (wData['breakfast'] != null &&
                wData['breakfast'].toString().trim().isNotEmpty)
              bf = wData['breakfast'];
            if (wData['lunch'] != null &&
                wData['lunch'].toString().trim().isNotEmpty)
              lu = wData['lunch'];
            if (wData['dinner'] != null &&
                wData['dinner'].toString().trim().isNotEmpty)
              dn = wData['dinner'];
          } // 2. Daily override
          final daySnap = snapshot.data![1];
          if (daySnap.exists && daySnap.value != null) {
            final dData = Map<String, dynamic>.from(daySnap.value as Map);
            if (dData['breakfast'] != null &&
                dData['breakfast'].toString().trim().isNotEmpty)
              bf = dData['breakfast'];
            if (dData['lunch'] != null &&
                dData['lunch'].toString().trim().isNotEmpty)
              lu = dData['lunch'];
            if (dData['dinner'] != null &&
                dData['dinner'].toString().trim().isNotEmpty)
              dn = dData['dinner'];
          }
        }
        final now = realTime;
        final months = [
          '',
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        final days = [
          '',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        String dateStr =
            "${days[now.weekday]}, ${now.day} ${months[now.month]} ${now.year}"; // 3 Demo Photos for the cards // Breakfast // Lunch bowl // Dinner spread // Original Main Menu Viewer (Hidden by default)
        Widget mediaViewer;
        if (globalMenuIsPdf) {
          if (globalMenuUploadBytes != null) {
            mediaViewer = SizedBox(
              height: 400,
              child: SfPdfViewer.memory(globalMenuUploadBytes!),
            );
          } else if (globalMenuUrl != null &&
              globalMenuUrl!.isNotEmpty &&
              globalMenuUrl!.startsWith('http')) {
            mediaViewer = SizedBox(
              height: 400,
              child: SfPdfViewer.network(globalMenuUrl!),
            );
          } else if (globalMenuFile != null) {
            mediaViewer = SizedBox(
              height: 400,
              child: SfPdfViewer.file(globalMenuFile!),
            );
          } else {
            mediaViewer = const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "No menu uploaded",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        } else {
          if (globalMenuUploadBytes != null) {
            mediaViewer = InteractiveViewer(
              child: Center(child: Image.memory(globalMenuUploadBytes!)),
            );
          } else if (globalMenuUrl != null &&
              globalMenuUrl!.isNotEmpty &&
              globalMenuUrl!.startsWith('http')) {
            mediaViewer = InteractiveViewer(
              child: Center(child: Image.network(globalMenuUrl!)),
            );
          } else if (globalMenuFile != null && !kIsWeb) {
            mediaViewer = InteractiveViewer(
              child: Center(child: Image.file(globalMenuFile!)),
            );
          } else {
            mediaViewer = const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "No menu uploaded",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
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
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ), // Breakfast Card
              _buildMealCard(
                icon: "🌅",
                title: "BREAKFAST",
                items: bf,
                color: const Color(0xFF4CAF50),
                imageOnRight: true,
              ),
              const SizedBox(height: 16), // Lunch Card
              _buildMealCard(
                icon: "☀️",
                title: "LUNCH",
                items: lu,
                color: const Color(0xFF4CAF50),
                imageOnRight: false,
              ),
              const SizedBox(height: 16), // Dinner Card
              _buildMealCard(
                icon: "🌙",
                title: "DINNER",
                items: dn,
                color: const Color(0xFF7B68EE),
                imageOnRight: true,
              ),
              const SizedBox(height: 24), // Hidden Uploaded Menu Section
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ExpansionTile(
                    title: const Text(
                      "📄 View Original Menu",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Click to view the menu uploaded by Admin",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white.withOpacity(0.7),
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 500),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
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
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        color: color.withOpacity(0.15),
      ),
      child: Center(
        child: Icon(
          title.toLowerCase().contains("breakfast")
              ? Icons.free_breakfast
              : title.toLowerCase().contains("lunch")
              ? Icons.lunch_dining
              : Icons.dinner_dining,
          color: color,
          size: 40,
        ),
      ),
    ); // Parse items by comma
    List<String> itemList = items
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    Widget textContent = Expanded(
      child: Column(
        crossAxisAlignment: imageOnRight
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
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
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...itemList.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
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
    this.studentPhotoUrl, [
    this.complaintImageUrl,
  ]);
}

Widget buildComplaintImageWidget(String imgData, {double height = 150}) {
  if (imgData.startsWith('data:image') || !imgData.startsWith('http')) {
    try {
      String clean = imgData.contains(',') ? imgData.split(',').last : imgData;
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(clean),
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image,
            color: brandGray,
          ),
        ),
      );
    } catch (_) {}
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      imgData,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.broken_image,
        color: brandGray,
      ),
    ),
  );
}

ImageProvider? getSafeImageProvider(String? urlOrBase64) {
  if (urlOrBase64 == null || urlOrBase64.isEmpty) return null;
  if (urlOrBase64.startsWith('data:image') || !urlOrBase64.startsWith('http')) {
    try {
      String clean = urlOrBase64.contains(',') ? urlOrBase64.split(',').last : urlOrBase64;
      return MemoryImage(base64Decode(clean));
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(urlOrBase64);
}

class ComplaintWindowConfig {
  final bool isOpen;
  final String mode; // 'toggle' or 'dates'
  final String? startDate; // 'YYYY-MM-DD'
  final String? endDate; // 'YYYY-MM-DD'
  final int maxPerMonth;
  final String? noticeMessage;

  ComplaintWindowConfig({
    this.isOpen = true,
    this.mode = 'toggle',
    this.startDate,
    this.endDate,
    this.maxPerMonth = 2,
    this.noticeMessage,
  });

  bool isCurrentlyOpen() {
    if (mode == 'dates' && startDate != null && endDate != null && startDate!.isNotEmpty && endDate!.isNotEmpty) {
      try {
        final now = realTime;
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        return todayStr.compareTo(startDate!) >= 0 && todayStr.compareTo(endDate!) <= 0;
      } catch (e) {
        return isOpen;
      }
    }
    return isOpen;
  }

  Map<String, dynamic> toJson() {
    return {
      'isOpen': isOpen,
      'mode': mode,
      'startDate': startDate,
      'endDate': endDate,
      'maxPerMonth': maxPerMonth,
      'noticeMessage': noticeMessage,
    };
  }

  factory ComplaintWindowConfig.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return ComplaintWindowConfig();
    return ComplaintWindowConfig(
      isOpen: json['isOpen'] == true,
      mode: (json['mode'] ?? 'toggle').toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      maxPerMonth: int.tryParse(json['maxPerMonth']?.toString() ?? '2') ?? 2,
      noticeMessage: json['noticeMessage']?.toString(),
    );
  }
}

ComplaintWindowConfig globalComplaintWindowConfig = ComplaintWindowConfig(isOpen: true, maxPerMonth: 2);

List<ComplaintItem> globalComplaints = [];
Set<String> globalStudentHiddenComplaints = {};
Set<String> globalStudentHiddenNotices = {};
Set<String> globalAdminHiddenComplaints = {};
DateTime globalStudentLastViewedNotices = DateTime(2000);
Future<void> saveStudentHiddenComplaints() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    'hiddenComplaints',
    globalStudentHiddenComplaints.toList(),
  );
}

Future<void> saveAdminHiddenComplaints() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    'adminHiddenComplaints',
    globalAdminHiddenComplaints.toList(),
  );
}

Set<String> globalAdminHiddenNotices = {};
Set<String> globalAdminDismissedDues = {};
Future<void> saveAdminDismissedDues() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    'adminDismissedDues',
    globalAdminDismissedDues.toList(),
  );
}
const Map<int, Map<String, String>> defaultWeeklyMenu = {
  DateTime.monday: {
    'breakfast': 'ચા, કોફી અને પૌંઆ',
    'lunch': 'ભીંડી મસાલા, ચણા, દાલ (મીઠી/તીખી), ચાવલ, રોટી, સલાડ',
    'dinner': 'દમ આલુ, વેજ બિરયાની, રોટી, સલાડ',
  },
  DateTime.tuesday: {
    'breakfast': 'ચા, કોફી, મસાલા પુરી/ મેંદુ વડા',
    'lunch':
        'કેબીજ મટર, મુંગ, દહીં/છાશ, દાલ (મીઠી/તીખી), ચાવલ, રોટી, સલાડ, છાશ, ગોળ',
    'dinner': 'મિક્સ વેજ, દાલ ફ્રાય, જીરા રાઇસ, રોટી, સલાડ',
  },
  DateTime.wednesday: {
    'breakfast': 'ચા, કોફી, થેપલા/ચિલા',
    'lunch':
        'આલુ ગોબી (ફુલાવર), ચણા મસાલા, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ, સલાડ',
    'dinner': 'દાલ બાટી, લસુન ચટણી, પાપડ, લીંબુ',
  },
  DateTime.thursday: {
    'breakfast': 'ચા, કોફી, ઉપમા',
    'lunch':
        'ચણા દાલ, બેગન મસાલા/સોયાબીન, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ, સલાડ, ગોળ',
    'dinner': 'પનીર મસાલા, ફ્રાય રાઇસ, રોટી, સલાડ',
  },
  DateTime.friday: {
    'breakfast': 'ચા, કોફી, આલુ પરાઠા/સેન્ડવીચ ઢોકળા',
    'lunch':
        'મિક્સ વેજ (ઊંધિયું), તુવેર, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ/દહીં, સલાડ',
    'dinner': 'ભાજી, પરોઠા, પુલાવ સલાડ',
  },
  DateTime.saturday: {
    'breakfast': 'ચા, કોફી, સમોસા/સેવ ખમણી',
    'lunch':
        'આલુ પ્યાસ, ચણા/ ચોલી, દાલ (મીઠી/તીખી), ચાવલ, રોટી, છાશ/દહીં, સલાડ, ગોળ',
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
  String? fcmToken;
  RegisteredStudent(
    this.name,
    this.roomNo,
    this.photoUrl,
    this.pin, {
    this.email = '',
    this.fcmToken,
  });
  Map<String, dynamic> toJson() => {
    'name': name,
    'roomNo': roomNo,
    'photoUrl': photoUrl ?? '',
    'pin': pin,
    'email': email,
    if (fcmToken != null && fcmToken!.isNotEmpty) 'fcmToken': fcmToken,
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
      fcmToken: parseNullableStr(json['fcmToken']),
    );
  }
  bool get isValid => name.isNotEmpty && roomNo.isNotEmpty;
}

Future<void> saveRegisteredStudents() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> strs = globalRegisteredStudents
      .map((s) => jsonEncode(s.toJson()))
      .toList();
  await prefs.setStringList('globalRegisteredStudents', strs);
}

class RoleDefinition {
  final String id;
  final String name;
  final Map<String, bool> permissions;

  RoleDefinition({
    required this.id,
    required this.name,
    required this.permissions,
  });

  factory RoleDefinition.fromJson(String id, Map<String, dynamic> json) {
    Map<String, bool> perms = {};
    if (json['permissions'] != null && json['permissions'] is Map) {
      (json['permissions'] as Map).forEach((k, v) {
        perms[k.toString()] = v == true;
      });
    }
    return RoleDefinition(
      id: id,
      name: (json['name'] ?? id).toString(),
      permissions: perms,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'permissions': permissions,
  };
}

Map<String, RoleDefinition> globalRoles = {
  'super_admin': RoleDefinition(
    id: 'super_admin',
    name: 'Super Admin',
    permissions: {
      'can_manage_polls': true,
      'can_manage_meals': true,
      'can_set_menu': true,
      'can_edit_timetable': true,
      'can_attendance': true,
      'can_attendance_edit': true,
      'can_students_manage': true,
      'can_complaints': true,
      'can_manage_complaint_window': true,
      'can_notices': true,
      'can_manage_admins': true,
    },
  ),
  'admin': RoleDefinition(
    id: 'admin',
    name: 'Admin',
    permissions: {
      'can_manage_polls': true,
      'can_manage_meals': true,
      'can_set_menu': true,
      'can_edit_timetable': true,
      'can_attendance': true,
      'can_attendance_edit': true,
      'can_students_manage': true,
      'can_complaints': true,
      'can_manage_complaint_window': true,
      'can_notices': true,
      'can_manage_admins': true,
    },
  ),
  'mess_committee': RoleDefinition(
    id: 'mess_committee',
    name: 'Mess Committee',
    permissions: {
      'can_manage_polls': true,
      'can_manage_meals': false,
      'can_set_menu': false,
      'can_edit_timetable': false,
      'can_attendance': false,
      'can_attendance_edit': false,
      'can_students_manage': false,
      'can_complaints': true,
      'can_manage_complaint_window': false,
      'can_notices': true,
      'can_manage_admins': false,
    },
  ),
  'professor': RoleDefinition(
    id: 'professor',
    name: 'Professor / Warden',
    permissions: {
      'can_manage_polls': false,
      'can_manage_meals': false,
      'can_set_menu': false,
      'can_edit_timetable': false,
      'can_attendance': true,
      'can_attendance_edit': false,
      'can_students_manage': false,
      'can_complaints': true,
      'can_manage_complaint_window': true,
      'can_notices': true,
      'can_manage_admins': false,
    },
  ),
};

class AdminUser {
  String phone;
  String pin;
  String email;
  String name;
  String? photoUrl;
  String role;
  String hostelScope; // 'both', 'boys', or 'girls'
  Map<String, bool>? customPermissions;
  bool isVerified;

  AdminUser(
    this.phone,
    this.pin, {
    this.email = '',
    this.name = 'Admin',
    this.photoUrl,
    this.role = 'admin',
    this.hostelScope = 'both',
    this.customPermissions,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'pin': pin,
    'email': email,
    'name': name,
    'photoUrl': photoUrl,
    'role': role,
    'hostelScope': hostelScope,
    'isVerified': isVerified,
    if (customPermissions != null) 'customPermissions': customPermissions,
  };

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    Map<String, bool>? perms;
    if (json['customPermissions'] != null && json['customPermissions'] is Map) {
      perms = {};
      (json['customPermissions'] as Map).forEach((k, v) {
        perms![k.toString()] = v == true;
      });
    }
    return AdminUser(
      (json['phone'] ?? '').toString(),
      (json['pin'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? 'Admin').toString(),
      photoUrl: json['photoUrl']?.toString(),
      role: (json['role'] ?? 'admin').toString(),
      hostelScope: (json['hostelScope'] ?? 'both').toString(),
      customPermissions: perms,
      isVerified: json['isVerified'] == true,
    );
  }
}

bool checkAdminPermission(String phone, String permKey) {
  final cleanPhone = phone.trim();
  AdminUser? admin;
  try {
    admin = globalAdmins.firstWhere((a) => a.phone.trim() == cleanPhone);
  } catch (e) {
    admin = null;
  }
  if (admin == null) return false;
  if (admin.customPermissions != null && admin.customPermissions!.containsKey(permKey)) {
    return admin.customPermissions![permKey] == true;
  }
  final roleDef = globalRoles[admin.role];
  if (roleDef != null && roleDef.permissions.containsKey(permKey)) {
    return roleDef.permissions[permKey] == true;
  }
  // Fallback if role in DB has not yet been saved with split menu/timetable keys:
  if (permKey == 'can_set_menu' || permKey == 'can_edit_timetable') {
    if (admin.customPermissions != null && admin.customPermissions!.containsKey('can_manage_meals')) {
      return admin.customPermissions!['can_manage_meals'] == true;
    }
    if (roleDef != null && roleDef.permissions.containsKey('can_manage_meals')) {
      return roleDef.permissions['can_manage_meals'] == true;
    }
  }
  if (admin.role == 'super_admin' || admin.role == 'admin') return true;
  return false;
}

String? cachedAdminScope;

String getAdminHostelScope(String phone) {
  final cleanPhone = phone.trim();
  AdminUser? admin;
  try {
    admin = globalAdmins.firstWhere((a) => a.phone.trim() == cleanPhone);
  } catch (e) {
    admin = null;
  }
  if (admin != null) {
    final s = admin.hostelScope.trim().toLowerCase();
    cachedAdminScope = s;
    if (s == 'boys' || s == 'girls') return s;
    return 'both';
  }
  if (cachedAdminScope != null && cachedAdminScope!.trim().isNotEmpty) {
    final s = cachedAdminScope!.trim().toLowerCase();
    if (s == 'boys' || s == 'girls') return s;
  }
  return 'both';
}

Future<AdminUser?> findAdminAcrossHostels(String phone) async {
  final clean = phone.trim();
  try {
    return globalAdmins.firstWhere((a) => a.phone.trim() == clean);
  } catch (_) {}
  for (String h in ['boys', 'girls']) {
    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData_$h/admins').get();
      if (snap.exists && snap.value != null) {
        var raw = snap.value;
        var list = raw is List ? raw : (raw is Map ? raw.values : []);
        for (var a in list) {
          if (a != null && a is Map) {
            var au = AdminUser.fromJson(Map<String, dynamic>.from(a));
            if (au.phone.trim() == clean) {
              if (!globalAdmins.any((x) => x.phone.trim() == clean)) {
                globalAdmins.add(au);
              }
              return au;
            }
          }
        }
      }
    } catch (_) {}
  }
  return null;
}

String getAdminRoleDisplayName(String phone) {
  final cleanPhone = phone.trim();
  AdminUser? admin;
  try {
    admin = globalAdmins.firstWhere((a) => a.phone.trim() == cleanPhone);
  } catch (e) {
    admin = null;
  }
  if (admin != null) {
    if (globalRoles.containsKey(admin.role) && globalRoles[admin.role]!.name.isNotEmpty) {
      return globalRoles[admin.role]!.name;
    }
    final normRole = admin.role.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    if (globalRoles.containsKey(normRole) && globalRoles[normRole]!.name.isNotEmpty) {
      return globalRoles[normRole]!.name;
    }
    if (admin.role == 'super_admin') return 'Super Admin';
    if (normRole == 'mess_committee' || normRole == 'mess_commitee') return 'Mess Committee';
    if (normRole == 'professor') return 'Professor / Warden';
    if (normRole == 'admin') return 'Hostel Admin';
    return admin.role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
  return 'Admin';
}

List<AdminUser> globalAdmins = [
  AdminUser(
    "9586401483",
    "c984aed014aec7623a54f0591da07a85fd4b762d68a75e0ac3f3d7a45b6a1e4c",
  ),
];
List<RegisteredStudent> globalRegisteredStudents = [];
String globalHostelMode = 'boys';
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();
int globalServerTimeOffset = 0;
int globalAppStartTime = DateTime.now().millisecondsSinceEpoch;
DateTime get realTime => DateTime.now().add(Duration(milliseconds: globalServerTimeOffset));
void handleForceLogout() async {
  SyncService.cancelAllStreams();
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
int globalLunchCloseHour = 14;
int globalLunchCloseMinute = 30;
int globalDinnerCloseHour = 21;
int globalDinnerCloseMinute = 30;
String globalLunchOpenedDate = '';
String globalDinnerOpenedDate = '';

bool isPastLunchCloseTime() {
  final now = realTime;
  final todayStr = "${now.year}-${now.month}-${now.day}";
  if (globalLunchOpenedDate.isNotEmpty && globalLunchOpenedDate != todayStr) {
    return true;
  }
  if (now.hour > globalLunchCloseHour) return true;
  if (now.hour == globalLunchCloseHour && now.minute >= globalLunchCloseMinute) return true;
  return false;
}

bool isPastDinnerCloseTime() {
  final now = realTime;
  final todayStr = "${now.year}-${now.month}-${now.day}";
  if (globalDinnerOpenedDate.isNotEmpty && globalDinnerOpenedDate != todayStr) {
    return true;
  }
  if (now.hour > globalDinnerCloseHour) return true;
  if (now.hour == globalDinnerCloseHour && now.minute >= globalDinnerCloseMinute) return true;
  return false;
}

String formatTimeOfDay(int hour, int minute) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final h = hour % 12 == 0 ? 12 : hour % 12;
  final m = minute.toString().padLeft(2, '0');
  return "$h:$m $period";
}

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
  String lTime = '';
  String dTime = '';
}

class DayPassTheme {
  final int weekday; // 1 = Monday, 7 = Sunday
  final String dayName;
  final String dayNameGu;
  final String colorName;
  final String colorNameGu;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color badgeBgColor;

  const DayPassTheme({
    required this.weekday,
    required this.dayName,
    required this.dayNameGu,
    required this.colorName,
    required this.colorNameGu,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.badgeBgColor,
  });
}

final Map<int, DayPassTheme> dayPassThemes = {
  1: const DayPassTheme(
    weekday: 1,
    dayName: 'Monday',
    dayNameGu: 'સોમવાર',
    colorName: 'Royal Blue',
    colorNameGu: 'રોયલ બ્લુ',
    emoji: '🟦',
    primaryColor: Color(0xFF1E3A8A),
    secondaryColor: Color(0xFF2563EB),
    accentColor: Color(0xFF93C5FD),
    badgeBgColor: Color(0xFF0F172A),
  ),
  2: const DayPassTheme(
    weekday: 2,
    dayName: 'Tuesday',
    dayNameGu: 'મંગળવાર',
    colorName: 'Emerald Green',
    colorNameGu: 'એમરાલ્ડ ગ્રીન',
    emoji: '🟩',
    primaryColor: Color(0xFF064E3B),
    secondaryColor: Color(0xFF059669),
    accentColor: Color(0xFF6EE7B7),
    badgeBgColor: Color(0xFF022C22),
  ),
  3: const DayPassTheme(
    weekday: 3,
    dayName: 'Wednesday',
    dayNameGu: 'બુધવાર',
    colorName: 'Royal Purple',
    colorNameGu: 'રોયલ પર્પલ',
    emoji: '🟪',
    primaryColor: Color(0xFF581C87),
    secondaryColor: Color(0xFF7C3AED),
    accentColor: Color(0xFFC4B5FD),
    badgeBgColor: Color(0xFF3B0764),
  ),
  4: const DayPassTheme(
    weekday: 4,
    dayName: 'Thursday',
    dayNameGu: 'ગુરુવાર',
    colorName: 'Golden Amber',
    colorNameGu: 'ગોલ્ડન એમ્બર',
    emoji: '🟧',
    primaryColor: Color(0xFF9A3412),
    secondaryColor: Color(0xFFD97706),
    accentColor: Color(0xFFFDE68A),
    badgeBgColor: Color(0xFF451A03),
  ),
  5: const DayPassTheme(
    weekday: 5,
    dayName: 'Friday',
    dayNameGu: 'શુક્રવાર',
    colorName: 'Ocean Teal',
    colorNameGu: 'ઓશન ટીલ',
    emoji: '🩵',
    primaryColor: Color(0xFF0F766E),
    secondaryColor: Color(0xFF0D9488),
    accentColor: Color(0xFF99F6E4),
    badgeBgColor: Color(0xFF134E4A),
  ),
  6: const DayPassTheme(
    weekday: 6,
    dayName: 'Saturday',
    dayNameGu: 'શનિવાર',
    colorName: 'Ruby Crimson',
    colorNameGu: 'રૂબી ક્રિમસન',
    emoji: '🟥',
    primaryColor: Color(0xFF881337),
    secondaryColor: Color(0xFFE11D48),
    accentColor: Color(0xFFFDA4AF),
    badgeBgColor: Color(0xFF4C0519),
  ),
  7: const DayPassTheme(
    weekday: 7,
    dayName: 'Sunday',
    dayNameGu: 'રવિવાર',
    colorName: 'Midnight Indigo',
    colorNameGu: 'મિડનાઇટ ઇન્ડિગો',
    emoji: '🟪',
    primaryColor: Color(0xFF312E81),
    secondaryColor: Color(0xFF4F46E5),
    accentColor: Color(0xFFA5B4FC),
    badgeBgColor: Color(0xFF1E1B4B),
  ),
};

DayPassTheme getTodayPassTheme([DateTime? dt]) {
  final now = dt ?? realTime;
  return dayPassThemes[now.weekday] ?? dayPassThemes[1]!;
}

int globalTenderPrice = 70;
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
  HardwareKeyboard.instance.addHandler((KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.printScreen) {
      Clipboard.setData(const ClipboardData(text: ''));
      return true;
    }
    return false;
  });
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
    print(
      "Firebase Initialized Successfully",
    );
    if (!kIsWeb) {
      try {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
      } catch (e) {
        print("Firebase persistence: $e");
      }
    }
    FirebaseDatabase.instance.ref('.info/serverTimeOffset').onValue.listen((event) {
      globalServerTimeOffset = (event.snapshot.value as num?)?.toInt() ?? 0;
    });
    // Initialize Notification Service
    await NotificationService.init();
    await _loadDataFromPrefs();
    SyncService.listen();
  } catch (e) {
    print("Firebase Init Error: $e");
  }
  runApp(const MyApp());
} // Global Brand Colors for consistency

const Color brandGreen = Color(0xFFEA580C);
const Color brandBg = Color(0xFFF6F8FC);
const Color brandInputBg = Color(0xFFEFF3FC);
const Color brandDark = Color(0xFF0F172A);
const Color brandGray = Color(0xFF64748B);

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.20,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: child,
        ),
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
        // We used to remove userType here to force login on update. // Removed this so users stay logged in after OTA update.
      }
    }
  } catch (e) {}
  List<String>? adminStrs = prefs.getStringList('globalAdmins');
  if (adminStrs != null && adminStrs.isNotEmpty) {
    globalAdmins = adminStrs
        .map((s) => AdminUser.fromJson(jsonDecode(s)))
        .toList();
  } // Load local-only hidden notices/complaints from SharedPreferences
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
  List<String>? savedAdminHiddenComplaints = prefs.getStringList(
    'adminHiddenComplaints',
  );
  if (savedAdminHiddenComplaints != null) {
    globalAdminHiddenComplaints.clear();
    globalAdminHiddenComplaints.addAll(savedAdminHiddenComplaints);
  }
  List<String>? savedDismissedDues = prefs.getStringList('adminDismissedDues');
  if (savedDismissedDues != null) {
    globalAdminDismissedDues.clear();
    globalAdminDismissedDues.addAll(savedDismissedDues);
  }
  List<String>? studentStrs = prefs.getStringList('globalRegisteredStudents');
  if (studentStrs != null && studentStrs.isNotEmpty) {
    // If we have saved students, overwrite the fake ones completely
    globalRegisteredStudents = studentStrs
        .map((s) => RegisteredStudent.fromJson(jsonDecode(s)))
        .where((s) => s.isValid)
        .toList();
  }
  String? userType = prefs.getString('userType');
  String? savedHostelMode = prefs.getString('hostelMode');
  String? savedAdminScope = prefs.getString('last_admin_scope');
  if (savedAdminScope != null && savedAdminScope.isNotEmpty) {
    cachedAdminScope = savedAdminScope.trim().toLowerCase();
  }
  if (savedHostelMode != null) globalHostelMode = savedHostelMode;
  if (userType == 'admin') {
    globalStudentSuffix = null;
    String? phone = prefs.getString('identifier');
    String? photoUrl = prefs.getString('photoPath');
    String? name = prefs.getString('extraInfo');
    if (phone != null) {
      if (savedAdminScope == 'boys') {
        globalHostelMode = 'boys';
      } else if (savedAdminScope == 'girls') {
        globalHostelMode = 'girls';
      }
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
    if (name != null && room != null) {
      globalStudentSuffix = "_${room}_$name";
      bool existsInCache = globalRegisteredStudents.any(
        (s) => s.name == name && s.roomNo == room,
      );
      if (globalRegisteredStudents.isNotEmpty && !existsInCache) {
        await prefs.remove('userType');
        await prefs.remove('identifier');
        await prefs.remove('extraInfo');
        await prefs.remove('photoPath');
        await prefs.remove('last_student_name');
        await prefs.remove('last_student_room');
        await prefs.remove('last_student_photo');
        initialScreen = const LoginScreen();
      } else {
        initialScreen = StudentDashboardScreen(
          photoUrl: photoUrl,
          name: name,
          roomNo: room,
        );
      }
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
  int actualBill = presentMealsCount * globalTenderPrice;
  return math.max(actualBill, 44 * globalTenderPrice);
}

class SyncService {
  static DatabaseReference get _dbRef =>
      FirebaseDatabase.instance.ref('hostelData_$globalHostelMode');
  static bool _isSyncingIn = false;
  static bool _hasDownloadedOnce = false;
  static int _lastHash = 0;
  static String _lastMenuPath = "";
  static String _lastDownloadedMenuBase64 = "";
  static bool _switchCooldown = false;
  static bool get isSwitchCooldown => _switchCooldown;
  static void setSwitchCooldown(bool val) => _switchCooldown = val;
  static bool _pollCooldown = false;
  static StreamSubscription? _firebaseSub;
  static void cancelAllStreams() {
    _firebaseSub?.cancel();
  }
  static Future<void> switchMode(String mode) async {
    globalHostelMode = mode;
    _hasDownloadedOnce = false;
    _lastHash = 0;
    globalMenuFile = null;
    globalMenuUrl = null;
    globalMenuUploadBytes = null;
    globalMenuIsPdf = false;
    _lastDownloadedMenuBase64 = "";
    _lastMenuPath = "";
    globalNotices.clear();
    globalComplaints.clear();
    globalRegisteredStudents.clear();
    globalAdmins.clear();
    dynamicPolls.clear();
    globalAttendanceMap.clear();
    globalMonthlyPaid.clear();
    globalEntryL = false;
    globalEntryD = false;
    _switchCooldown = false;
    globalComplaintWindowConfig = ComplaintWindowConfig(isOpen: true, maxPerMonth: 2);
    await _firebaseSub?.cancel();
    listen();
    globalSyncTrigger.value++; // Force UI refresh immediately on toggle
    await fetchNow();
  }

  static Future<void> saveComplaintWindowConfig(ComplaintWindowConfig config) async {
    try {
      await _dbRef.child('complaint_window').set(config.toJson());
      globalComplaintWindowConfig = config;
      globalSyncTrigger.value++;
    } catch (e) {
      print("Save complaint window error: $e");
    }
  }

  static Map<String, DynamicPoll> dynamicPolls = {};
  static Future<void> createDynamicPoll(DynamicPoll poll) async {
    try {
      await _dbRef.child('dynamic_polls').child(poll.id).set(poll.toJson());
    } catch (e) {
      print("Create poll error: $e");
    }
  }

  static Future<void> updateDynamicPoll(DynamicPoll poll) async {
    try {
      if (dynamicPolls.containsKey(poll.id)) {
        dynamicPolls[poll.id] = poll;
      }
      await _dbRef.child('dynamic_polls').child(poll.id).set(poll.toJson());
      globalSyncTrigger.value++;
    } catch (e) {
      print("Update poll error: $e");
    }
  }

  static Future<void> stopDynamicPoll(String id) async {
    try {
      await _dbRef.child('dynamic_polls').child(id).update({'isActive': false});
    } catch (e) {
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
    } catch (e) {
      print("Delete poll error: $e");
    }
  }

  /// Firebase keys cannot contain . # $ [ ] /
  static String pollSafeKey(String key) =>
      key.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
  static Future<void> voteDynamicPoll(
    String pollId,
    String studentKey,
    String option,
  ) async {
    studentKey = pollSafeKey(studentKey);
    try {
      if (dynamicPolls[pollId] != null) {
        dynamicPolls[pollId]!.votes[studentKey] = option;
        globalSyncTrigger.value++;
      }
      await _dbRef
          .child('dynamic_polls')
          .child(pollId)
          .child('votes')
          .child(studentKey)
          .set(option);
    } catch (e) {
      print("Vote poll error: $e");
    }
  }

  static Future<void> removeVoteDynamicPoll(
    String pollId,
    String studentKey,
  ) async {
    studentKey = pollSafeKey(studentKey);
    try {
      if (dynamicPolls[pollId] != null) {
        dynamicPolls[pollId]!.votes.remove(studentKey);
        globalSyncTrigger.value++;
      }
      await _dbRef
          .child('dynamic_polls')
          .child(pollId)
          .child('votes')
          .child(studentKey)
          .remove();
    } catch (e) {
      print("Remove vote error: $e");
    }
  }

  static String attendanceSafeKey(String key) => key.replaceAll(RegExp(r'[.#$\[\]/]'), '_');

  static Future<void> pushAttendanceMeal(String key, String meal, String status) async {
    final safeKey = attendanceSafeKey(key);
    try {
      await _dbRef.child('attendance').child(safeKey).update({meal: status});
    } catch (e) {
      print("Push attendance meal error: $e");
    }
  }

  static Future<void> pushAttendanceBatch(Map<String, dynamic> updates) async {
    try {
      if (updates.isNotEmpty) {
        Map<String, dynamic> safeUpdates = {};
        updates.forEach((k, v) {
          if (k.contains('/')) {
            var parts = k.split('/');
            safeUpdates["${attendanceSafeKey(parts[0])}/${parts[1]}"] = v;
          } else {
            safeUpdates[attendanceSafeKey(k)] = v;
          }
        });
        await _dbRef.child('attendance').update(safeUpdates);
        globalSyncTrigger.value++;
      }
    } catch (e) {
      print("Push attendance batch error: $e");
    }
  }

  static Future<void> pushAttendance(String key, DailyRecord rec) async {
    final safeKey = attendanceSafeKey(key);
    try {
      Map<String, dynamic> updateData = {
        'l': rec.l,
        'd': rec.d,
        if (rec.lTime.isNotEmpty) 'lt': rec.lTime,
        if (rec.dTime.isNotEmpty) 'dt': rec.dTime,
      };
      await _dbRef.child('attendance').child(safeKey).update(updateData);
      globalSyncTrigger.value++;
    } catch (e) {
      print("Push attendance error: $e");
    }
  }

  static Future<void> pushTenderPrice(int price) async {
    try {
      globalTenderPrice = price;
      await _dbRef.child('tender_price').set(price);
      await _dbRef.child('switches').child('tenderPrice').set(price);
      globalSyncTrigger.value++;
    } catch (e) {
      print("Push tender price error: $e");
    }
  }

  /// Delete notice from Firebase and Supabase bridge
  static Future<void> deleteNotice(String id) async {
    try {
      final safeId = id.replaceAll(RegExp(r'[.#$\[\]/\s]'), '_');
      globalNotices.removeWhere((n) => n.id == id || n.id == safeId);
      globalSyncTrigger.value++;
      await _dbRef.child('notices').child(safeId).remove();
      _deleteNoticeFromSupabase(id);
      _deleteNoticeFromSupabase(safeId);
    } catch (e) {
      print("Delete notice error: $e");
    }
  }

  static Future<void> deleteComplaint(String id) async {
    try {
      final safeId = id.replaceAll(RegExp(r'[.#$\[\]/\s]'), '_');
      var compIdx = globalComplaints.indexWhere((c) => c.id == id || c.id == safeId);
      if (compIdx != -1) {
        globalComplaints.removeAt(compIdx);
      }
      globalAdminHiddenComplaints.add(id);
      globalAdminHiddenComplaints.add(safeId);
      await saveAdminHiddenComplaints();
      globalSyncTrigger.value++;
      await _dbRef.child('complaints').child(safeId).remove();
      _deleteComplaintFromSupabase(id);
      _deleteComplaintFromSupabase(safeId);
    } catch (e) {
      print("Delete complaint error: $e");
    }
  }

  static Future<void> fetchNow() async {
    try {
      // 1. Fetch from Firebase
      final snap = await _dbRef.get();
      if (snap.exists && snap.value != null) {
        Map<dynamic, dynamic> rawData = snap.value as Map<dynamic, dynamic>;
        try {
          if (rawData['menu'] != null) {
            globalMenuIsPdf = rawData['menu']['isPdf'] ?? false;
            String menuBase64 = rawData['menu']['fileBase64'] ?? '';
            if (menuBase64.isNotEmpty && !kIsWeb) {
              final dir = await getApplicationDocumentsDirectory();
              String ext = globalMenuIsPdf ? 'pdf' : 'jpg';
              File mFile = File(
                '${dir.path}/mess_menu_${realTime.millisecondsSinceEpoch}.$ext',
              );
              await mFile.writeAsBytes(base64Decode(menuBase64));
              globalMenuFile = mFile;
            } else if (menuBase64.isNotEmpty && kIsWeb) {
              globalMenuUploadBytes = base64Decode(menuBase64);
            } else {
              globalMenuFile = null;
            }
          }
        } catch (e) {}
        Map<String, dynamic> data = jsonDecode(jsonEncode(rawData));
        if (data.containsKey('admins') && data['admins'] != null) {
          globalAdmins.clear();
          var adminsData = data['admins'];
          var adminsList = adminsData is List
              ? adminsData
              : (adminsData is Map ? adminsData.values : []);
          for (var a in adminsList) {
            if (a != null) {
              globalAdmins.add(
                AdminUser.fromJson(Map<String, dynamic>.from(a)),
              );
            }
          }
        }
        globalMonthlyPaid.clear();
        if (data['paid'] != null) {
          (data['paid'] as Map).forEach((k, v) {
            globalMonthlyPaid[k.toString()] = (v as num).toInt();
          });
        }
        // CRITICAL: Don't overwrite switches or attendance during cooldown
        // (admin just toggled OFF and is pushing absent marks)
        if (!_switchCooldown) {
          globalEntryL = false;
          globalEntryD = false;
          if (data['tender_price'] != null) {
            globalTenderPrice = int.tryParse(data['tender_price'].toString()) ?? 70;
          } else if (data['switches'] != null && data['switches']['tenderPrice'] != null) {
            globalTenderPrice = int.tryParse(data['switches']['tenderPrice'].toString()) ?? 70;
          }
          if (data['switches'] != null) {
            globalEntryL = data['switches']['globalEntryL'] ?? false;
            globalEntryD = data['switches']['globalEntryD'] ?? false;
            globalLunchCloseHour = data['switches']['lunchCloseHour'] ?? 14;
            globalLunchCloseMinute = data['switches']['lunchCloseMinute'] ?? 30;
            globalDinnerCloseHour = data['switches']['dinnerCloseHour'] ?? 21;
            globalDinnerCloseMinute = data['switches']['dinnerCloseMinute'] ?? 30;
            globalLunchOpenedDate = data['switches']['lunchOpenedDate'] ?? '';
            globalDinnerOpenedDate = data['switches']['dinnerOpenedDate'] ?? '';
          }
          globalAttendanceMap.clear();
          if (data['attendance'] != null) {
            (data['attendance'] as Map).forEach((k, v) {
              String kStr = k.toString();
              if (globalStudentSuffix != null &&
                  !kStr.endsWith(globalStudentSuffix!) &&
                  !attendanceSafeKey(kStr).endsWith(attendanceSafeKey(globalStudentSuffix!))) {
                return;
              }
              var rec = DailyRecord();
              rec.l = v['l'] ?? '';
              rec.d = v['d'] ?? '';
              rec.lTime = v['lt'] ?? '';
              rec.dTime = v['dt'] ?? '';
              String safeK = attendanceSafeKey(kStr);
              globalAttendanceMap[safeK] = rec;
              if (safeK != kStr) {
                globalAttendanceMap[kStr] = rec;
              }
            });
          }
        }
        SyncService.dynamicPolls.clear();
        if (data['dynamic_polls'] != null) {
          (data['dynamic_polls'] as Map).forEach((k, v) {
            dynamicPolls[k.toString()] = DynamicPoll.fromJson(v, k.toString());
          });
        }
        globalRegisteredStudents.clear();
        if (data['students'] != null) {
          var studentsData = data['students'];
          var studentsList = studentsData is List
              ? studentsData
              : (studentsData is Map ? studentsData.values : []);
          for (var s in studentsList) {
            if (s != null) {
              var st = RegisteredStudent.fromJson(Map<String, dynamic>.from(s));
              if (st.isValid) globalRegisteredStudents.add(st);
            }
          }
        }
        if (data['complaint_window'] != null) {
          globalComplaintWindowConfig = ComplaintWindowConfig.fromJson(
            Map<dynamic, dynamic>.from(data['complaint_window']),
          );
        }
        if (data['notices'] != null) {
          globalNotices.clear();
          (data['notices'] as Map).forEach((k, v) {
            if (v != null) {
              globalNotices.add(
                NoticeItem(
                  v['id']?.toString() ?? k.toString(),
                  v['title']?.toString() ?? '',
                  v['message']?.toString() ?? '',
                  DateTime.tryParse(v['date']?.toString() ?? '') ?? realTime,
                ),
              );
            }
          });
          globalNotices.sort((a, b) => b.date.compareTo(a.date));
        }
        if (data['complaints'] != null) {
          globalComplaints.clear();
          (data['complaints'] as Map).forEach((k, v) {
            if (v != null) {
              String? sPhoto = v['student_photo']?.toString();
              if (sPhoto == null || sPhoto.isEmpty) {
                try {
                  sPhoto = globalRegisteredStudents
                      .firstWhere(
                        (s) =>
                            s.roomNo == v['student_room'] &&
                            s.name == v['student_name'],
                      )
                      .photoUrl;
                } catch (e) {}
              }
              globalComplaints.add(
                ComplaintItem(
                  v['id']?.toString() ?? k.toString(),
                  v['title']?.toString() ?? '',
                  v['description']?.toString() ?? '',
                  DateTime.tryParse(v['date']?.toString() ?? '') ?? realTime,
                  v['student_name']?.toString() ?? '',
                  v['student_room']?.toString() ?? '',
                  sPhoto,
                  v['image_url']?.toString(),
                ),
              );
            }
          });
          globalComplaints.sort((a, b) => b.date.compareTo(a.date));
        }
        await saveRegisteredStudents();
        _hasDownloadedOnce = true;
      }
      await _fetchSupabaseFallbacks();
      globalSyncTrigger.value++;
    } catch (e) {
      print("Manual Fetch Error: $e");
    }
  }

  static const String _supabaseUrl = 'https://whliroffubcqsalxdqfs.supabase.co/rest/v1';
  static const String _supabaseKey = 'sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe';
  static Map<String, String> get _supabaseHeaders => {
    'apikey': _supabaseKey,
    'Authorization': 'Bearer $_supabaseKey',
    'Content-Type': 'application/json',
    'Prefer': 'resolution=merge-duplicates',
  };

  static Future<void> _syncNoticeToSupabase(NoticeItem n, String? targetHostel) async {
    try {
      final dio = Dio();
      final body = {
        'id': n.id,
        'title': n.title,
        'message': n.message,
        'date': n.date.toIso8601String(),
      };
      if (targetHostel == 'both') {
        await dio.post('$_supabaseUrl/notices_boys', data: body, options: Options(headers: _supabaseHeaders));
        await dio.post('$_supabaseUrl/notices_girls', data: body, options: Options(headers: _supabaseHeaders));
      } else if (targetHostel == 'girls') {
        await dio.post('$_supabaseUrl/notices_girls', data: body, options: Options(headers: _supabaseHeaders));
      } else {
        await dio.post('$_supabaseUrl/notices_boys', data: body, options: Options(headers: _supabaseHeaders));
      }
    } catch (e) {
      debugPrint("Supabase notice dual-sync error: $e");
    }
  }

  static Future<void> _syncComplaintToSupabase(ComplaintItem c) async {
    try {
      final dio = Dio();
      final body = {
        'id': c.id,
        'title': c.title,
        'description': c.description,
        'date': c.date.toIso8601String(),
        'student_name': c.studentName,
        'student_room': c.studentRoom,
        'image_url': c.complaintImageUrl ?? '',
      };
      await dio.post('$_supabaseUrl/complaints_$globalHostelMode', data: body, options: Options(headers: _supabaseHeaders));
    } catch (e) {
      debugPrint("Supabase complaint dual-sync error: $e");
    }
  }

  static Future<void> _deleteNoticeFromSupabase(String id) async {
    try {
      final dio = Dio();
      await dio.delete('$_supabaseUrl/notices_boys?id=eq.$id', options: Options(headers: _supabaseHeaders));
      await dio.delete('$_supabaseUrl/notices_girls?id=eq.$id', options: Options(headers: _supabaseHeaders));
    } catch (_) {}
  }

  static Future<void> _deleteComplaintFromSupabase(String id) async {
    try {
      final dio = Dio();
      await dio.delete('$_supabaseUrl/complaints_$globalHostelMode?id=eq.$id', options: Options(headers: _supabaseHeaders));
    } catch (_) {}
  }

  static Future<void> _fetchSupabaseFallbacks() async {
    try {
      final dio = Dio();
      dio.options.receiveTimeout = const Duration(seconds: 4);
      dio.options.sendTimeout = const Duration(seconds: 4);
      // Fetch Supabase notices
      final nRes = await dio.get('$_supabaseUrl/notices_$globalHostelMode?select=*', options: Options(headers: _supabaseHeaders));
      if (nRes.data is List) {
        bool changed = false;
        for (var item in nRes.data) {
          final id = item['id']?.toString() ?? '';
          if (id.isNotEmpty && !globalNotices.any((n) => n.id == id)) {
            globalNotices.add(NoticeItem(
              id,
              item['title']?.toString() ?? '',
              item['message']?.toString() ?? '',
              DateTime.tryParse(item['date']?.toString() ?? '') ?? realTime,
            ));
            changed = true;
          }
        }
        if (changed) {
          globalNotices.sort((a, b) => b.date.compareTo(a.date));
        }
      }
      // Fetch Supabase complaints
      final cRes = await dio.get('$_supabaseUrl/complaints_$globalHostelMode?select=*', options: Options(headers: _supabaseHeaders));
      if (cRes.data is List) {
        bool changed = false;
        for (var item in cRes.data) {
          final id = item['id']?.toString() ?? '';
          if (id.isNotEmpty && !globalComplaints.any((c) => c.id == id)) {
            String? sPhoto;
            try {
              sPhoto = globalRegisteredStudents.firstWhere((s) => s.roomNo == item['student_room'] && s.name == item['student_name']).photoUrl;
            } catch (_) {}
            globalComplaints.add(ComplaintItem(
              id,
              item['title']?.toString() ?? '',
              item['description']?.toString() ?? '',
              DateTime.tryParse(item['date']?.toString() ?? '') ?? realTime,
              item['student_name']?.toString() ?? '',
              item['student_room']?.toString() ?? '',
              sPhoto,
              item['image_url']?.toString(),
            ));
            changed = true;
          }
        }
        if (changed) {
          globalComplaints.sort((a, b) => b.date.compareTo(a.date));
        }
      }
    } catch (_) {}
  }

  static Future<void> pushSingleNotice(NoticeItem n, {String? targetHostel}) async {
    try {
      final safeId = n.id.replaceAll(RegExp(r'[.#$\[\]/\s]'), '_');
      final data = {
        'id': safeId,
        'title': n.title,
        'message': n.message,
        'date': n.date.toIso8601String(),
      };
      if (targetHostel == 'both') {
        await FirebaseDatabase.instance.ref('hostelData_boys/notices').child(safeId).set(data);
        await FirebaseDatabase.instance.ref('hostelData_girls/notices').child(safeId).set(data);
      } else if (targetHostel == 'boys') {
        await FirebaseDatabase.instance.ref('hostelData_boys/notices').child(safeId).set(data);
      } else if (targetHostel == 'girls') {
        await FirebaseDatabase.instance.ref('hostelData_girls/notices').child(safeId).set(data);
      } else {
        await _dbRef.child('notices').child(safeId).set(data);
      }
      // Dual-sync to Supabase for backward compatibility with v1.0.127
      _syncNoticeToSupabase(n, targetHostel);
      globalSyncTrigger.value++;
    } catch (e) {
      print("Push notices error: $e");
    }
  }

  /// Push only single complaint to Firebase and dual-sync to Supabase
  static Future<void> pushSingleComplaint(ComplaintItem c) async {
    try {
      final safeId = c.id.replaceAll(RegExp(r'[.#$\[\]/\s]'), '_');
      String photoUrl = c.complaintImageUrl ?? "";
      await _dbRef.child('complaints').child(safeId).set({
        'id': safeId,
        'title': c.title,
        'description': c.description,
        'date': c.date.toIso8601String(),
        'student_name': c.studentName,
        'student_room': c.studentRoom,
        'student_photo': c.studentPhotoUrl ?? '',
        'image_url': photoUrl,
      });
      // Dual-sync to Supabase for backward compatibility with v1.0.127
      _syncComplaintToSupabase(c);
      globalSyncTrigger.value++;
    } catch (e) {
      print("Push complaint error: $e");
    }
  }

  /// Target-update a single payment record to prevent race conditions
  static Future<void> pushPaidTargeted(String monthKey, int amount) async {
    try {
      await _dbRef.child('paid').child(monthKey).set(amount);
      globalSyncTrigger.value++;
    } catch (e) {
      print("Push paid error: $e");
    }
  }

  /// Target-update a single student to prevent race conditions
  static Future<void> updateStudentTargeted(RegisteredStudent target) async {
    try {
      int idx = globalRegisteredStudents.indexWhere(
          (s) => s.name == target.name && s.roomNo == target.roomNo);
      if (idx == -1) return;
      
      Map<String, dynamic> updateData = {
        'name': target.name,
        'roomNo': target.roomNo,
        'pin': target.pin,
        'photoUrl': target.photoUrl ?? "",
        'email': target.email,
      };
      // Preserve FCM token
      if (target.fcmToken != null && target.fcmToken!.isNotEmpty) {
        updateData['fcmToken'] = target.fcmToken;
      }
      
      await _dbRef.child('students').child(idx.toString()).update(updateData);
      globalSyncTrigger.value++;
    } catch (e) {
      print("Update student targeted error: $e");
    }
  }

  /// Push only students list to Firebase
  static Future<void> pushStudents() async {
    try {
      List<Map<String, dynamic>> studentsList = [];
      for (var s in globalRegisteredStudents) {
        Map<String, dynamic> stMap = {
          'name': s.name,
          'roomNo': s.roomNo,
          'pin': s.pin,
          'photoUrl': s.photoUrl ?? "",
          'email': s.email,
        };
        // CRITICAL: Preserve FCM token so notifications keep working
        if (s.fcmToken != null && s.fcmToken!.isNotEmpty) {
          stMap['fcmToken'] = s.fcmToken;
        }
        studentsList.add(stMap);
      }

      await _dbRef.child('students').set(studentsList);
      await _dbRef.child('students_trigger').set(realTime.millisecondsSinceEpoch);
      globalSyncTrigger.value++;
    } catch (e) {
      print("Push students error: $e");
    }
  }

  /// Push only admins list to Firebase
  static Future<void> pushAdmins() async {
    try {
      Map<String, dynamic> updates = {};
      for (int i = 0; i < globalAdmins.length; i++) {
        var a = globalAdmins[i];
        updates['$i/phone'] = a.phone;
        updates['$i/pin'] = a.pin;
        updates['$i/name'] = a.name;
        updates['$i/email'] = a.email;
        updates['$i/photoUrl'] = a.photoUrl ?? "";
        updates['$i/role'] = a.role;
        updates['$i/hostelScope'] = a.hostelScope;
        updates['$i/isVerified'] = a.isVerified;
        if (a.customPermissions != null) {
          updates['$i/customPermissions'] = a.customPermissions;
        }
      }
      
      final snap = await _dbRef.child('admins').get();
      if (snap.exists && snap.value != null) {
        int cloudLen = 0;
        if (snap.value is List) {
          cloudLen = (snap.value as List).length;
        } else if (snap.value is Map) {
          cloudLen = (snap.value as Map).keys.length;
        }
        for (int i = globalAdmins.length; i < cloudLen; i++) {
          updates['$i'] = null;
        }
      }

      if (updates.isNotEmpty) {
        await _dbRef.child('admins').update(updates);
      }
      globalSyncTrigger.value++;
    } catch (e) {
      print("Push admins error: $e");
    }
  }

  /// Syncs an individual admin record directly to Firebase across both boys/girls databases
  static Future<void> syncAdminRecord(AdminUser admin) async {
    for (String mode in ['boys', 'girls']) {
      try {
        final snap = await FirebaseDatabase.instance.ref('hostelData_$mode/admins').get();
        if (snap.exists && snap.value != null) {
          var snapVal = snap.value;
          var adminsList = snapVal is List ? snapVal : (snapVal is Map ? snapVal.values.toList() : []);
          bool matched = false;
          List<dynamic> updated = [];
          for (var item in adminsList) {
            if (item != null) {
              var map = Map<String, dynamic>.from(item is Map ? item : {});
              if (map['phone'].toString().trim() == admin.phone.trim()) {
                map['pin'] = admin.pin;
                map['isVerified'] = admin.isVerified;
                map['email'] = admin.email;
                if (admin.photoUrl != null && admin.photoUrl!.isNotEmpty) {
                  map['photoUrl'] = admin.photoUrl;
                }
                matched = true;
              }
              updated.add(map);
            }
          }
          if (matched) {
            await FirebaseDatabase.instance.ref('hostelData_$mode/admins').set(updated);
          }
        }
      } catch (e) {
        print("syncAdminRecord error for $mode: $e");
      }
    }
  }

  /// Push only menu to Firebase
  static Future<void> pushMenu() async {
    if (globalMenuFile == null && globalMenuUploadBytes == null) {
      try {
        await _dbRef.child('menu').remove();
        globalSyncTrigger.value++;
      } catch (e) {}
      return;
    }
    try {
      final bytes =
          globalMenuUploadBytes ?? await globalMenuFile!.readAsBytes();
      final fileBase64 = base64Encode(bytes);
      await _dbRef.child('menu').set({
        'isPdf': globalMenuIsPdf,
        'fileBase64': fileBase64,
        'updated_at': realTime.toIso8601String(),
      });
      globalSyncTrigger.value++;
    } catch (e) {
      print("Push menu error: $e");
      throw Exception("Menu Upload Error: $e");
    }
  }

  /// Immediately push ONLY the switches node to Firebase.
  static Future<void> pushSwitchesNow() async {
    _switchCooldown = true;
    try {
      await _dbRef.child('switches').set({
        'globalEntryL': globalEntryL,
        'globalEntryD': globalEntryD,
        'lunchCloseHour': globalLunchCloseHour,
        'lunchCloseMinute': globalLunchCloseMinute,
        'dinnerCloseHour': globalDinnerCloseHour,
        'dinnerCloseMinute': globalDinnerCloseMinute,
        'lunchOpenedDate': globalLunchOpenedDate,
        'dinnerOpenedDate': globalDinnerOpenedDate,
        'tenderPrice': globalTenderPrice,
      });
      globalSyncTrigger.value++;
    } catch (e) {
      print("Push switches error: $e");
    }
    Future.delayed(const Duration(milliseconds: 1500), () {
      _switchCooldown = false;
    });
  }

  static Future<void> autoCloseIfExpired(String meal) async {
    try {
      if (meal == 'l' && (globalEntryL || isPastLunchCloseTime())) {
        globalEntryL = false;
        await _dbRef.child('switches').child('globalEntryL').set(false);
        globalSyncTrigger.value++;
      } else if (meal == 'd' && (globalEntryD || isPastDinnerCloseTime())) {
        globalEntryD = false;
        await _dbRef.child('switches').child('globalEntryD').set(false);
        globalSyncTrigger.value++;
      }
    } catch (e) {
      print("Auto close error: $e");
    }
  }

  static int _computeHash(Map<String, dynamic> data) {
    return jsonEncode(data).hashCode;
  }

  static Future<void> pushAll() async {
    if (_isSyncingIn) return;
    if (!_hasDownloadedOnce && globalRegisteredStudents.isEmpty)
      return; // Prevent wiping cloud on fresh install
    Map<String, dynamic> data = {};
    List<Map<String, dynamic>> studentsList = [];
    for (var s in globalRegisteredStudents) {
      String photoUrl = s.photoUrl ?? '';
      Map<String, dynamic> studentMap = {
        'name': s.name,
        'roomNo': s.roomNo,
        'pin': s.pin,
        'photoUrl': photoUrl,
        'email': s.email,
      };
      // CRITICAL: Preserve FCM token so notifications keep working
      if (s.fcmToken != null && s.fcmToken!.isNotEmpty) {
        studentMap['fcmToken'] = s.fcmToken;
      }
      studentsList.add(studentMap);
    }
    data['students'] = studentsList;
    Map<String, dynamic> attendanceData = {};
    globalAttendanceMap.forEach((k, v) {
      attendanceData[k] = {'l': v.l, 'd': v.d};
    });
    data['attendance'] = attendanceData;
    data['paid'] = globalMonthlyPaid;
    List<Map<String, dynamic>> adminsList = [];
    for (var a in globalAdmins) adminsList.add(a.toJson());
    data['admins'] =
        adminsList; // NOTE: dynamic_polls, notices, complaints, and menu are pushed via targeted updates.
    data['switches'] = {
      'globalEntryL': globalEntryL,
      'globalEntryD': globalEntryD,
    }; // hiddenNotices & hiddenComplaints are now LOCAL ONLY (SharedPreferences) // They are NOT pushed to Firebase anymore to prevent cross-device deletion
    data['adminLastViewed'] = globalAdminLastViewedComplaints.toIso8601String();
    int currentHash = _computeHash(data);
    if (currentHash == _lastHash) return; // No changes!
    _lastHash = currentHash; // Wait, we need real base64 for upload.
    for (var s in data['students']) {
      String photoB64 = s['photoBase64'] ?? s['photoUrl'] ?? '';
      if (photoB64.isNotEmpty && !kIsWeb) {
        try {
          File f = File(photoB64);
          if (f.existsSync()) {
            s['photoBase64'] = base64Encode(await f.readAsBytes());
          } else {
            s['photoBase64'] = "";
          }
        } catch (e) {
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

  static void listen() {
    _firebaseSub?.cancel();
    _firebaseSub = _dbRef.onValue.listen((event) async {
      final snap = event.snapshot;
      if (snap.value == null) return;
      _isSyncingIn = true;
      _hasDownloadedOnce = true;
      try {
        Map<dynamic, dynamic> data =
            snap.value as Map<dynamic, dynamic>;
        if (data.containsKey('admins') && data['admins'] != null) {
          globalAdmins.clear();
          var adminsData = data['admins'];
          var adminsList = adminsData is List
              ? adminsData
              : (adminsData is Map ? adminsData.values : []);
          for (var a in adminsList) {
            if (a != null) {
              globalAdmins.add(
                AdminUser.fromJson(Map<String, dynamic>.from(a)),
              );
            }
          }
        }
        globalMonthlyPaid.clear();
        if (data['paid'] != null) {
          (data['paid'] as Map).forEach((k, v) {
            globalMonthlyPaid[k.toString()] = (v as num).toInt();
          });
        }
        // CRITICAL: Don't overwrite switches or attendance during cooldown
        if (!_switchCooldown) {
          globalEntryL = false;
          globalEntryD = false;
          if (data['tender_price'] != null) {
            globalTenderPrice = int.tryParse(data['tender_price'].toString()) ?? 70;
          } else if (data['switches'] != null && data['switches']['tenderPrice'] != null) {
            globalTenderPrice = int.tryParse(data['switches']['tenderPrice'].toString()) ?? 70;
          }
          if (data['switches'] != null) {
            globalEntryL = data['switches']['globalEntryL'] ?? false;
            globalEntryD = data['switches']['globalEntryD'] ?? false;
            globalLunchCloseHour = data['switches']['lunchCloseHour'] ?? 14;
            globalLunchCloseMinute = data['switches']['lunchCloseMinute'] ?? 30;
            globalDinnerCloseHour = data['switches']['dinnerCloseHour'] ?? 21;
            globalDinnerCloseMinute = data['switches']['dinnerCloseMinute'] ?? 30;
            globalLunchOpenedDate = data['switches']['lunchOpenedDate'] ?? '';
            globalDinnerOpenedDate = data['switches']['dinnerOpenedDate'] ?? '';
          }
          globalAttendanceMap.clear();
          if (data['attendance'] != null) {
            (data['attendance'] as Map).forEach((k, v) {
              String kStr = k.toString();
              if (globalStudentSuffix != null &&
                  !kStr.endsWith(globalStudentSuffix!) &&
                  !attendanceSafeKey(kStr).endsWith(attendanceSafeKey(globalStudentSuffix!))) {
                return;
              }
              var rec = DailyRecord();
              rec.l = v['l'] ?? '';
              rec.d = v['d'] ?? '';
              rec.lTime = v['lt'] ?? '';
              rec.dTime = v['dt'] ?? '';
              String safeK = attendanceSafeKey(kStr);
              globalAttendanceMap[safeK] = rec;
              if (safeK != kStr) {
                globalAttendanceMap[kStr] = rec;
              }
            });
          }
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
              if (kIsWeb) return;
              final dir = await getApplicationDocumentsDirectory();
              String ext = globalMenuIsPdf ? 'pdf' : 'jpg';
              File mFile = File(
                '${dir.path}/mess_menu_${realTime.millisecondsSinceEpoch}.$ext',
              );
              await mFile.writeAsBytes(base64Decode(menuBase64));
              globalMenuFile = mFile;
              _lastMenuPath = mFile.path;
            } else {
              globalMenuFile = null;
              _lastMenuPath = "";
            }
          }
        }
        if (data['switches'] != null && !_switchCooldown) {
          globalEntryL = data['switches']['globalEntryL'] ?? false;
          globalEntryD = data['switches']['globalEntryD'] ?? false;
        } // hiddenNotices & hiddenComplaints are LOCAL ONLY - don't load from Firebase // They stay in SharedPreferences per-device
        if (data['adminLastViewed'] != null) {
          globalAdminLastViewedComplaints = DateTime.parse(
            data['adminLastViewed'],
          );
        }
        globalRegisteredStudents.clear();
        if (data['students'] != null) {
          var studentsData = data['students'];
          var studentsList = studentsData is List
              ? studentsData
              : (studentsData is Map ? studentsData.values : []);
          for (var s in studentsList) {
            if (s != null) {
              var st = RegisteredStudent.fromJson(Map<String, dynamic>.from(s));
              if (st.isValid) globalRegisteredStudents.add(st);
            }
          }
        }
        if (data['complaint_window'] != null) {
          globalComplaintWindowConfig = ComplaintWindowConfig.fromJson(
            Map<dynamic, dynamic>.from(data['complaint_window']),
          );
        }
        if (data['notices'] != null) {
          globalNotices.clear();
          (data['notices'] as Map).forEach((k, v) {
            if (v != null) {
              globalNotices.add(
                NoticeItem(
                  v['id']?.toString() ?? k.toString(),
                  v['title']?.toString() ?? '',
                  v['message']?.toString() ?? '',
                  DateTime.tryParse(v['date']?.toString() ?? '') ?? realTime,
                ),
              );
            }
          });
          globalNotices.sort((a, b) => b.date.compareTo(a.date));
        }
        if (data['complaints'] != null) {
          globalComplaints.clear();
          (data['complaints'] as Map).forEach((k, v) {
            if (v != null) {
              String? sPhoto = v['student_photo']?.toString();
              if (sPhoto == null || sPhoto.isEmpty) {
                try {
                  sPhoto = globalRegisteredStudents
                      .firstWhere(
                        (s) =>
                            s.roomNo == v['student_room'] &&
                            s.name == v['student_name'],
                      )
                      .photoUrl;
                } catch (e) {}
              }
              globalComplaints.add(
                ComplaintItem(
                  v['id']?.toString() ?? k.toString(),
                  v['title']?.toString() ?? '',
                  v['description']?.toString() ?? '',
                  DateTime.tryParse(v['date']?.toString() ?? '') ?? realTime,
                  v['student_name']?.toString() ?? '',
                  v['student_room']?.toString() ?? '',
                  sPhoto,
                  v['image_url']?.toString(),
                ),
              );
            }
          });
          globalComplaints.sort((a, b) => b.date.compareTo(a.date));
        }
        await saveRegisteredStudents();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'globalAdmins',
          globalAdmins.map((a) => jsonEncode(a.toJson())).toList(),
        );
        globalSyncTrigger.value++;
      } catch (e) {
        print("Sync Listen Error: $e");
      }
      _isSyncingIn = false;
    }); // REMOVED: The 1-second pushAll() loop was causing data overwrites // between multiple phones. Now using targeted push methods instead. // Each action (swipe, poll, notice, etc.) pushes ONLY its own data.
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
            primaryColor: brandGreen,
            scaffoldBackgroundColor: brandBg,
            colorScheme: ColorScheme.fromSeed(seedColor: brandGreen),
          ),
          builder: (context, child) {
            return ResponsiveWrapper(child: child!);
          },
          home: SplashScreen(
            nextScreen: UpdateCheckerWrapper(
              child: initialScreen ?? const LoginScreen(),
            ),
          ),
        );
      },
    );
  }
} // ============================================================================= // EMAIL OTP VERIFICATION SERVICE // ============================================================================= // Render backend URL for Email/OTP verification

const String _backendBaseUrl = 'https://hostel-backend-pdph.onrender.com';

class EmailOtpService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _backendBaseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Validate email format + domain via backend
  static Future<Map<String, dynamic>> verifyEmail(String email) async {
    try {
      final response = await _dio.post('/verify-email', data: {'email': email});
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {
        'valid': false,
        'message': 'Network error. Please check your connection.',
      };
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
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Verify OTP entered by user
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await _dio.post(
        '/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {
        'valid': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }
}

/// Shows a full-screen OTP verification flow dialog.
/// Returns true if OTP was verified successfully, false otherwise.
Future<bool> showOtpVerificationDialog(
  BuildContext context,
  String email, {
  bool autoSend = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _OtpVerificationDialog(email: email, autoSend: autoSend),
  );
  return result ?? false;
}

class _OtpVerificationDialog extends StatefulWidget {
  final String email;
  final bool autoSend;
  const _OtpVerificationDialog({required this.email, this.autoSend = true});
  @override
  State<_OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<_OtpVerificationDialog> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
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
    if (widget.autoSend) {
      _sendOtp();
    } else {
      _otpSent = true;
      _statusMessage = "OTP sent! Check your email inbox.";
      _startCooldown();
    }
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: brandGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Email Verification",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: brandDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter the 6-digit OTP sent to\n${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: brandGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28), // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 44,
                    height: 52,
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
                        contentPadding: EdgeInsets.zero,
                        counterText: "",
                        filled: true,
                        fillColor: brandInputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: brandGreen,
                            width: 2,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: brandDark,
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && i < 5) {
                          _otpFocusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          _otpFocusNodes[i - 1].requestFocus();
                        } // Auto-verify when all 6 digits entered
                        if (i == 5 && val.isNotEmpty) {
                          String fullOtp = _otpControllers
                              .map((c) => c.text)
                              .join();
                          if (fullOtp.length == 6) _verifyOtp();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20), // Status message
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _isError ? Colors.redAccent : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isError
                                ? Colors.redAccent
                                : Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24), // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_otpSent && !_isVerifying && !_isSending)
                      ? _verifyOtp
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Verify OTP",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14), // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive OTP? ",
                    style: TextStyle(fontSize: 13, color: brandGray),
                  ),
                  GestureDetector(
                    onTap: (_resendCooldown <= 0 && !_isSending)
                        ? () {
                            for (var c in _otpControllers) c.clear();
                            _sendOtp();
                          }
                        : null,
                    child: Text(
                      _isSending
                          ? "Sending..."
                          : (_resendCooldown > 0
                                ? "Resend (${_resendCooldown}s)"
                                : "Resend"),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (_resendCooldown <= 0 && !_isSending)
                            ? brandGreen
                            : brandGray,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14), // Cancel
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: brandGray, fontSize: 13),
                ),
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

enum AuthStage {
  identifier,
  standardPassword,
  adminEmail,
  newPassword,
  personalPassword,
  otp,
}

class _LoginScreenState extends State<LoginScreen> {
  bool isStudent = true;
  bool _isCreatingPassword = false;
  AuthStage _authStage = AuthStage.identifier;
  bool _isAdminFlow = false;
  AdminUser? _matchedAdmin;
  RegisteredStudent? _matchedStudent;
  String _adminVerificationId = '';
  bool isStudentPinVisible = false;
  bool isAdminPassVisible = false;
  String? selectedStudentName;
  final _studentFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>(); // Controllers to fetch data
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentPinController = TextEditingController();
  final TextEditingController _studentRePinController = TextEditingController();
  final TextEditingController _studentEmailController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _adminMobileController = TextEditingController();
  final TextEditingController _adminPasswordController =
      TextEditingController();
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
    rooms.sort(
      (a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0),
    );
    return rooms;
  }

  @override
  void initState() {
    super.initState();
    globalSyncTrigger.addListener(_onSync);
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    globalSyncTrigger.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    if (!mounted) return;
    if (hasSavedStudent && globalRegisteredStudents.isNotEmpty) {
      bool exists = globalRegisteredStudents.any(
        (s) => s.name == savedStudentName && s.roomNo == savedStudentRoom,
      );
      if (!exists) {
        _clearSavedStudent();
      }
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedStudentName = prefs.getString('last_student_name');
      String? savedMode = prefs.getString('hostelMode');
      if (savedMode != null) globalHostelMode = savedMode;
      savedStudentRoom = prefs.getString('last_student_room');
      savedStudentPhoto = prefs.getString('last_student_photo');
      hasSavedStudent =
          savedStudentName != null && savedStudentName!.isNotEmpty;
      savedAdminPhone = prefs.getString('last_admin_phone');
      savedAdminName = prefs.getString('last_admin_name');
      savedAdminPhoto = prefs.getString('last_admin_photo');
      hasSavedAdmin = savedAdminPhone != null && savedAdminPhone!.isNotEmpty;
      if (hasSavedStudent) {
        if (globalRegisteredStudents.isNotEmpty) {
          bool exists = globalRegisteredStudents.any(
            (s) => s.name == savedStudentName && s.roomNo == savedStudentRoom,
          );
          if (!exists) {
            hasSavedStudent = false;
            _clearSavedStudent();
          }
        }
        if (hasSavedStudent) {
          selectedRoom = savedStudentRoom;
          selectedStudentName = savedStudentName;
          studentPhotoUrl = savedStudentPhoto;
          isStudent = true;
        }
      }
      if (hasSavedAdmin) {
        _adminMobileController.text = savedAdminPhone!;
        _adminNameController.text = savedAdminName ?? "";
        adminPhotoUrl = savedAdminPhoto;
        isStudent = false;
        _isAdminFlow = true;
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
    await prefs.remove('last_admin_scope');
    cachedAdminScope = null;
    setState(() {
      hasSavedAdmin = false;
      _isAdminFlow = false;
      _matchedAdmin = null;
      _adminMobileController.clear();
      _adminNameController.clear();
      adminPhotoUrl = null;
      _adminPasswordController.clear();
      _adminEmailVerified = false;
      _studentPinController.clear();
      _studentRePinController.clear();
      _authStage = AuthStage.identifier;
    });
  }

  String? _validatePassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (password.length > 16) return 'Password must be at most 16 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password))
      return 'Must contain at least 1 uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(password))
      return 'Must contain at least 1 number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password))
      return 'Must contain at least 1 special character';
    return null;
  }

  Future<void> _pickImage(bool isStudentForm) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (image == null) return; // Circular crop
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: const Color(0xFF2E7D32),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop Photo'),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 400, height: 400),
          ),
        ],
      );
      if (croppedFile == null) return;
      final bytes = await croppedFile.readAsBytes();
      final base64Photo = "data:image/jpeg;base64,${base64Encode(bytes)}";
      setState(() {
        if (isStudentForm) {
          studentPhotoUrl = base64Photo;
        } else {
          adminPhotoUrl = base64Photo;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Photo attached!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  /// Validates email via backend, then shows OTP dialog
  Future<void> _verifyEmailAndOtp({required bool isStudentForm}) async {
    if (isStudentForm && !hasSavedStudent) {
      if (selectedRoom == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a room first.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (selectedStudentName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your name first.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      String typedPin = _studentPinController.text.trim();
      String hashedTypedPin = hashPassword(typedPin);
      if (typedPin.length != 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be 8 characters.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      try {
        final snap = await FirebaseDatabase.instance
            .ref('hostelData_$globalHostelMode/students')
            .get();
        if (snap.exists && snap.value != null) {
          globalRegisteredStudents.clear();
          var snapVal = snap.value;
          var studentsList = snapVal is List
              ? snapVal
              : (snapVal is Map ? snapVal.values : []);
          for (var s in studentsList) {
            if (s != null) {
              var st = RegisteredStudent.fromJson(Map<String, dynamic>.from(s));
              if (st.isValid) globalRegisteredStudents.add(st);
            }
          }
        }
      } catch (e) {}
      var roomStudents = globalRegisteredStudents
          .where((s) => s.roomNo == selectedRoom!)
          .toList();
      RegisteredStudent? existingStudent;
      try {
        existingStudent = roomStudents.firstWhere(
          (s) => s.name.toLowerCase() == selectedStudentName!.toLowerCase(),
        );
      } catch (e) {}
      if (existingStudent != null) {
        if (existingStudent.pin.isEmpty) {
          if (typedPin != _studentRePinController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Passwords do not match'),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
        } else if (existingStudent.pin != typedPin &&
            existingStudent.pin != hashedTypedPin) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passwords do not match'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        if (roomStudents.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This room is full (Max 4 students).'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }
    } else if (!isStudentForm && !hasSavedAdmin) {
      if (_adminMobileController.text.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (_adminNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your name.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (_adminPasswordController.text.length != 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be exactly 8 characters.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      } // Check if admin exists and password matches
      String phone = _adminMobileController.text.trim();
      String pin = _adminPasswordController.text;
      AdminUser? admin;
      try {
        admin = globalAdmins.firstWhere((a) => a.phone == phone);
      } catch (e) {
        admin = null;
      }
      if (admin == null) {
        admin = await findAdminAcrossHostels(phone);
      }
      if (admin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Admin account not found. Please contact super admin.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      } else {
        if (admin.hostelScope.trim().toLowerCase() == 'boys') {
          globalHostelMode = 'boys';
        } else if (admin.hostelScope.trim().toLowerCase() == 'girls') {
          globalHostelMode = 'girls';
        }
        if (admin.pin != hashPassword(pin) && admin.pin != pin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect password!'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }
    }
    String? finalEmail;
    if (isStudentForm) {
      RegisteredStudent? student;
      var roomStudents = globalRegisteredStudents
          .where((s) => s.roomNo == selectedRoom!)
          .toList();
      try {
        student = roomStudents.firstWhere(
          (s) => s.name.toLowerCase() == selectedStudentName!.toLowerCase(),
        );
      } catch (e) {}
      if (student == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student not found in database.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      finalEmail = student.email;
      if (finalEmail == null || finalEmail.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your email is not registered. Please contact Admin to add your email.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    } else {
      finalEmail = _adminEmailController.text.trim();
    }
    final email = finalEmail.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    } // Basic regex check client-side first
    final emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(
      () => _isVerifyingEmail = true,
    ); // Step 1: Deep email validation via backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking email...'),
        duration: Duration(seconds: 2),
      ),
    );
    final validationResult = await EmailOtpService.verifyEmail(email);
    if (validationResult['valid'] != true) {
      setState(() => _isVerifyingEmail = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid email: ${validationResult['reason'] ?? validationResult['message'] ?? 'Unknown error'}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(
      () => _isVerifyingEmail = false,
    ); // Step 2: Send OTP and show verification dialog
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
          const SnackBar(
            content: Text('✅ Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleForgotPassword(bool isStudentReq) async {
    String? emailToSend;
    String? targetIdentifier;
    if (isStudentReq) {
      // Use matched student from unified login or saved credentials
      if (_matchedStudent != null) {
        emailToSend = _matchedStudent!.email;
        targetIdentifier = _matchedStudent!.name;
      } else if (hasSavedStudent && savedStudentName != null) {
        targetIdentifier = savedStudentName;
        try {
          var existingStudent = globalRegisteredStudents.firstWhere(
            (s) => s.name == targetIdentifier,
          );
          emailToSend = existingStudent.email;
        } catch (e) {}
      }
      if (targetIdentifier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot identify account for password reset."),
          ),
        );
        return;
      }
    } else {
      // Admin flow
      if (_matchedAdmin != null) {
        emailToSend = _matchedAdmin!.email;
        targetIdentifier = _matchedAdmin!.phone;
      } else if (hasSavedAdmin && savedAdminPhone != null) {
        targetIdentifier = savedAdminPhone;
        try {
          var admin = globalAdmins.firstWhere(
            (a) => a.phone == targetIdentifier,
          );
          emailToSend = admin.email;
        } catch (e) {}
      }
      if (emailToSend == null || emailToSend.isEmpty) {
        String searchPhone = targetIdentifier ?? _studentEmailController.text.trim();
        if (searchPhone.length == 10) {
          for (String mode in ['boys', 'girls']) {
            try {
              final snap = await FirebaseDatabase.instance.ref('hostelData_$mode/admins').get();
              if (snap.exists && snap.value != null) {
                var snapVal = snap.value;
                var list = snapVal is List ? snapVal : (snapVal is Map ? snapVal.values : []);
                for (var a in list) {
                  if (a != null && a['phone'] == searchPhone) {
                    emailToSend = (a['email'] ?? '').toString();
                    targetIdentifier = searchPhone;
                    break;
                  }
                }
              }
            } catch (e) {}
            if (emailToSend != null && emailToSend.isNotEmpty) break;
          }
        }
      }
      if (targetIdentifier == null || targetIdentifier.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot identify account for password reset."),
          ),
        );
        return;
      }
    }
    if (emailToSend == null || emailToSend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email found for this account.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    bool verified = await showOtpVerificationDialog(context, emailToSend);
    if (verified) {
      // Let them reset the password
      TextEditingController newPassCtrl = TextEditingController();
      TextEditingController rePassCtrl = TextEditingController();
      bool isForgotPinVisible = false;
      bool isForgotRePinVisible = false;
      bool resetDone =
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  backgroundColor: brandInputBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    "Reset Password",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: brandDark,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "New Password",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: brandDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: newPassCtrl,
                          obscureText: !isForgotPinVisible,
                          maxLength: 16,
                          onChanged: (val) => setStateDialog(() {}),
                          decoration: InputDecoration(
                            hintText: "Create password (8-16 chars)",
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: brandGray,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isForgotPinVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: brandGray,
                                size: 20,
                              ),
                              onPressed: () => setStateDialog(
                                () => isForgotPinVisible = !isForgotPinVisible,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            counterText: "",
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildPasswordHints(newPassCtrl.text),
                        const SizedBox(height: 16),
                        const Text(
                          "Confirm Password",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: brandDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: rePassCtrl,
                          obscureText: !isForgotRePinVisible,
                          maxLength: 16,
                          onChanged: (val) => setStateDialog(() {}),
                          decoration: InputDecoration(
                            hintText: "Re-enter password",
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: brandGray,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isForgotRePinVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: brandGray,
                                size: 20,
                              ),
                              onPressed: () => setStateDialog(
                                () => isForgotRePinVisible =
                                    !isForgotRePinVisible,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            counterText: "",
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: brandGray),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        String? validationError = _validatePassword(
                          newPassCtrl.text,
                        );
                        if (validationError != null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(validationError)),
                          );
                          return;
                        }
                        if (newPassCtrl.text != rePassCtrl.text) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text("Passwords do not match!"),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: const Text("Save"),
                    ),
                  ],
                );
              },
            ),
          ) ??
          false;
      if (resetDone) {
        if (isStudentReq) {
          var existingStudent =
              _matchedStudent ??
              globalRegisteredStudents.firstWhere(
                (s) =>
                    s.name.toLowerCase() ==
                    (savedStudentName ?? '').toLowerCase(),
              );
          existingStudent.pin = hashPassword(newPassCtrl.text);
          await saveRegisteredStudents();
          await SyncService.updateStudentTargeted(existingStudent);
        } else {
          AdminUser? admin = _matchedAdmin;
          if (admin == null && targetIdentifier != null) {
            try {
              admin = globalAdmins.firstWhere((a) => a.phone == targetIdentifier);
            } catch (e) {}
          }
          String hashed = hashPassword(newPassCtrl.text);
          if (admin != null) {
            admin.pin = hashed;
            admin.isVerified = true;
            await SyncService.syncAdminRecord(admin);
            int idx = globalAdmins.indexWhere((a) => a.phone == admin!.phone);
            if (idx != -1) {
              globalAdmins[idx] = admin;
            } else {
              globalAdmins.add(admin);
            }
          } else if (targetIdentifier != null) {
            AdminUser dummyAdmin = AdminUser(targetIdentifier, hashed, isVerified: true);
            await SyncService.syncAdminRecord(dummyAdmin);
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(
            'globalAdmins',
            globalAdmins.map((a) => jsonEncode(a.toJson())).toList(),
          );
          await SyncService.pushAdmins();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset successfully!"),
            backgroundColor: Colors.green,
          ),
        );
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
      var s = globalRegisteredStudents.firstWhere(
        (st) => st.roomNo == selectedRoom && st.name == selectedStudentName,
      );
      needsEmailAndRePin = s.pin.isEmpty;
    } catch (e) {} // Email verification check
    if (!hasSavedStudent && needsEmailAndRePin && !_studentEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please verify your email first by clicking "Verify Email"',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    String typedName = selectedStudentName!;
    String typedPin = _studentPinController.text.trim();
    String hashedTypedPin = hashPassword(
      typedPin,
    ); // Explicitly fetch latest from Firebase to prevent Web vs App mismatch bugs
    try {
      final snap = await FirebaseDatabase.instance
          .ref('hostelData_$globalHostelMode/students')
          .get();
      if (snap.exists && snap.value != null) {
        globalRegisteredStudents.clear();
        var snapVal = snap.value;
        var studentsList = snapVal is List
            ? snapVal
            : (snapVal is Map ? snapVal.values : []);
        for (var s in studentsList) {
          if (s != null) {
            var st = RegisteredStudent.fromJson(Map<String, dynamic>.from(s));
            if (st.isValid) globalRegisteredStudents.add(st);
          }
        }
      }
    } catch (e) {}
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password must be 8 characters'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        if (typedPin != _studentRePinController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passwords do not match'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        existingStudent.pin =
            hashedTypedPin; // Email is already in the database and handled via Admin
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password created successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (existingStudent.pin != typedPin &&
          existingStudent.pin != hashedTypedPin) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be 8 characters'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (typedPin != _studentRePinController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      globalRegisteredStudents.add(
        RegisteredStudent(
          typedName,
          selectedRoom!,
          studentPhotoUrl,
          hashedTypedPin,
          email: _studentEmailController.text.trim(),
        ),
      );
      await saveRegisteredStudents();
      await SyncService.updateStudentTargeted(existingStudent);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_student_name', typedName);
    await prefs.setString('last_student_room', selectedRoom!);
    await prefs.setString('last_student_photo', studentPhotoUrl ?? '');
    await prefs.setString('userType', 'student');
    await prefs.setString('hostelMode', globalHostelMode);
    await prefs.setString('identifier', typedName);
    await prefs.setString('photoPath', studentPhotoUrl ?? '');
    await prefs.setString('extraInfo', selectedRoom!);
    globalStudentSuffix = "_${selectedRoom!}_${typedName}";
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
      String pin = _adminPasswordController.text; // Find admin
      AdminUser? admin;
      try {
        admin = globalAdmins.firstWhere((a) => a.phone == phone);
      } catch (e) {
        admin = null;
      }
      if (admin == null) {
        admin = await findAdminAcrossHostels(phone);
      }
      if (admin != null) {
        if (admin.pin == hashPassword(pin) || admin.pin == pin) {
          if (admin.pin == pin) {
            // Upgrade legacy plaintext to hash
            admin.pin = hashPassword(pin);
            final p = await SharedPreferences.getInstance();
            await p.setStringList(
              'globalAdmins',
              globalAdmins.map((a) => jsonEncode(a.toJson())).toList(),
            );
            await SyncService.pushAdmins();
          } // Success
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_admin_phone', admin.phone);
          await prefs.setString('last_admin_name', _adminNameController.text);
          await prefs.setString('last_admin_photo', adminPhotoUrl ?? '');
          await prefs.setString('last_admin_scope', admin.hostelScope);
          cachedAdminScope = admin.hostelScope;
          globalStudentSuffix = null;
          await prefs.setString('userType', 'admin');
          String targetMode = admin.hostelScope.trim().toLowerCase() == 'girls'
              ? 'girls'
              : (admin.hostelScope.trim().toLowerCase() == 'boys' ? 'boys' : globalHostelMode);
          await prefs.setString('hostelMode', targetMode);
          await prefs.setString('identifier', admin.phone);
          await prefs.setString('photoPath', adminPhotoUrl ?? '');
          await prefs.setString('extraInfo', _adminNameController.text);
          await SyncService.switchMode(targetMode);
          await NotificationService.saveToken();
          final roleDisplayName = getAdminRoleDisplayName(admin.phone);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Welcome! Logged in as $roleDisplayName",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: brandGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboardScreen(
                photoUrl: adminPhotoUrl,
                name: _adminNameController.text.isNotEmpty ? _adminNameController.text : admin!.name,
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Builder(
                  builder: (context) {
                    String titleText = "Hostel Mess Management";
                    if (_authStage != AuthStage.identifier || hasSavedStudent || hasSavedAdmin) {
                      if (_isAdminFlow || hasSavedAdmin || _matchedAdmin != null) {
                        String scope = (_matchedAdmin?.hostelScope ??
                                cachedAdminScope ??
                                (hasSavedAdmin && savedAdminPhone != null ? getAdminHostelScope(savedAdminPhone!) : ''))
                            .trim()
                            .toLowerCase();
                        if (scope == 'both') {
                          titleText = "Boys / Girls Hostel Mess";
                        } else if (scope == 'girls') {
                          titleText = "Girls Hostel Mess";
                        } else if (scope == 'boys') {
                          titleText = "Boys Hostel Mess";
                        } else {
                          titleText = "${globalHostelMode == 'boys' ? 'Boys' : 'Girls'} Hostel Mess";
                        }
                      } else {
                        titleText = "${globalHostelMode == 'boys' ? 'Boys' : 'Girls'} Hostel Mess";
                      }
                    }
                    return Text(
                      titleText,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: brandDark,
                        letterSpacing: -0.5,
                      ),
                    );
                  },
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
              const SizedBox(height: 28), // Form
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
                child: _buildStudentPortal(),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Developed by",
                      style: TextStyle(
                        color: brandGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.asset(
                      'assets/mdhk_logo.png',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
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

  Future<void> _verifyIdentifierStage() async {
    String input = _studentEmailController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email id')),
      );
      return;
    }
    setState(() => _isVerifyingEmail = true);
    bool isNumeric = RegExp(r'^[0-9]+$').hasMatch(input) && input.length == 10;
    if (isNumeric) {
      // === ADMIN FLOW ===
      _isAdminFlow = true;
      _matchedAdmin = null; // Search BOTH boys and girls admin databases
      for (String mode in ['boys', 'girls']) {
        try {
          final snap = await FirebaseDatabase.instance
              .ref('hostelData_$mode/admins')
              .get();
          if (snap.exists && snap.value != null) {
            List<AdminUser> tempAdmins = [];
            var snapVal = snap.value;
            var adminsList = snapVal is List
                ? snapVal
                : (snapVal is Map ? snapVal.values : []);
            for (var a in adminsList) {
              if (a != null) {
                tempAdmins.add(
                  AdminUser.fromJson(Map<String, dynamic>.from(a)),
                );
              }
            }
            for (var a in tempAdmins) {
              if (a.phone == input) {
                _matchedAdmin = a;
                globalHostelMode = mode;
                globalAdmins = tempAdmins;
                break;
              }
            }
          }
        } catch (e) {}
        if (_matchedAdmin != null) break;
      }
      if (_matchedAdmin == null) {
        setState(() => _isVerifyingEmail = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mobile number not found in staff records.')));
        return;
      }
      bool isFirstTime = !_matchedAdmin!.isVerified ||
          _matchedAdmin!.pin.isEmpty ||
          _matchedAdmin!.pin == 'Hostel@123' ||
          _matchedAdmin!.pin == hashPassword('Hostel@123');

      if (isFirstTime) {
        if (_matchedAdmin!.email.trim().isEmpty) {
          setState(() => _isVerifyingEmail = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No email registered for this staff account. Please contact Super Admin.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        setState(() {
          _isVerifyingEmail = false;
          _authStage = AuthStage.adminEmail;
          adminPhotoUrl = _matchedAdmin!.photoUrl;
          _studentPinController.clear();
          _studentRePinController.clear();
        });
      } else {
        setState(() {
          _isVerifyingEmail = false;
          _authStage = AuthStage.personalPassword;
          adminPhotoUrl = _matchedAdmin!.photoUrl;
          _studentPinController.clear();
        });
      }
      return;
    } // === STUDENT FLOW ===
    _isAdminFlow = false;
    String email = input.toLowerCase();
    if (!email.contains('@')) {
      setState(() => _isVerifyingEmail = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid Email format')));
      return;
    } // Search BOTH boys and girls student databases
    _matchedStudent = null;
    for (String mode in ['boys', 'girls']) {
      try {
        final snap = await FirebaseDatabase.instance
            .ref('hostelData_$mode/students')
            .get();
        if (snap.exists && snap.value != null) {
          List<RegisteredStudent> tempStudents = [];
          var snapVal = snap.value;
          var studentsList = snapVal is List
              ? snapVal
              : (snapVal is Map ? snapVal.values : []);
          for (var s in studentsList) {
            if (s != null) {
              var st = RegisteredStudent.fromJson(Map<String, dynamic>.from(s));
              if (st.isValid) tempStudents.add(st);
            }
          }
          for (var s in tempStudents) {
            if (s.email != null && s.email.toLowerCase() == email) {
              _matchedStudent = s;
              globalHostelMode = mode;
              globalRegisteredStudents = tempStudents;
              break;
            }
          }
        }
      } catch (e) {}
      if (_matchedStudent != null) break;
    }
    if (_matchedStudent == null) {
      setState(() => _isVerifyingEmail = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not registered. Please contact Admin.'),
        ),
      );
      return;
    }
    if (_matchedStudent!.pin.isNotEmpty) {
      setState(() {
        _isVerifyingEmail = false;
        _authStage = AuthStage.personalPassword;
        studentPhotoUrl = _matchedStudent!.photoUrl;
        selectedStudentName = _matchedStudent!.name;
        selectedRoom = _matchedStudent!.roomNo;
      });
    } else {
      Map<String, dynamic> res = await EmailOtpService.sendOtp(email);
      bool sent = res['success'] == true;
      setState(() => _isVerifyingEmail = false);
      if (sent) {
        bool verified =
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => _OtpVerificationDialog(email: email, autoSend: false),
            ) ??
            false;
        if (verified) {
          setState(() {
            _authStage = AuthStage.newPassword;
            selectedStudentName = _matchedStudent!.name;
            selectedRoom = _matchedStudent!.roomNo;
          });
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send OTP.')));
      }
    }
  }

  Future<void> _handleUnifiedAction() async {
    String typedPin = _studentPinController.text.trim();
    if (_isAdminFlow || (_authStage == AuthStage.personalPassword && hasSavedAdmin)) {
      if (_authStage == AuthStage.personalPassword) {
        AdminUser? admin = _matchedAdmin;
        if (admin == null && hasSavedAdmin && savedAdminPhone != null) {
          try {
            admin = globalAdmins.firstWhere((a) => a.phone == savedAdminPhone);
          } catch (e) {}
          if (admin == null) {
            for (String mode in ['boys', 'girls']) {
              try {
                final snap = await FirebaseDatabase.instance.ref('hostelData_$mode/admins').get();
                if (snap.exists && snap.value != null) {
                  var snapVal = snap.value;
                  var adminsList = snapVal is List ? snapVal : (snapVal is Map ? snapVal.values : []);
                  for (var a in adminsList) {
                    if (a != null && a['phone'] == savedAdminPhone) {
                      admin = AdminUser.fromJson(Map<String, dynamic>.from(a));
                      globalHostelMode = mode;
                      break;
                    }
                  }
                }
              } catch (e) {}
              if (admin != null) break;
            }
          }
        }
        if (admin == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff record not found. Please contact Super Admin.')),
          );
          return;
        }
        String hashed = hashPassword(typedPin);
        if (admin.pin == typedPin || admin.pin == hashed) {
          if (admin.pin == typedPin) {
            admin.pin = hashed;
            admin.isVerified = true;
            await SyncService.syncAdminRecord(admin);
          }
          await _finalizeAdminLogin(admin);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid Password!')));
        }
      } else if (_authStage == AuthStage.newPassword) {
        String? validationError = _validatePassword(typedPin);
        if (validationError != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(validationError)));
          return;
        }
        if (typedPin != _studentRePinController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match!')),
          );
          return;
        }
        if (_matchedAdmin == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff record not found!')),
          );
          return;
        }
        String hashed = hashPassword(typedPin);
        _matchedAdmin!.pin = hashed;
        _matchedAdmin!.isVerified = true;
        if (studentPhotoUrl != null && studentPhotoUrl!.isNotEmpty) {
          _matchedAdmin!.photoUrl = studentPhotoUrl;
        }
        await SyncService.syncAdminRecord(_matchedAdmin!);
        int idx = globalAdmins.indexWhere(
          (a) => a.phone == _matchedAdmin!.phone,
        );
        if (idx != -1) {
          globalAdmins[idx] = _matchedAdmin!;
        } else {
          globalAdmins.add(_matchedAdmin!);
        }
        final p = await SharedPreferences.getInstance();
        await p.setStringList(
          'globalAdmins',
          globalAdmins.map((a) => jsonEncode(a.toJson())).toList(),
        );
        await SyncService.pushAdmins();
        await _finalizeAdminLogin(_matchedAdmin!);
      }
      return;
    } // === STUDENT LOGIC ===
    if (_authStage == AuthStage.newPassword) {
      String? validationError = _validatePassword(typedPin);
      if (validationError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validationError)));
        return;
      }
      if (typedPin != _studentRePinController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match!')),
        );
        return;
      }
      _matchedStudent!.pin = hashPassword(typedPin);
      _matchedStudent!.photoUrl = studentPhotoUrl;
      int idx = globalRegisteredStudents.indexWhere(
        (s) =>
            s.name == _matchedStudent!.name &&
            s.roomNo == _matchedStudent!.roomNo,
      );
      if (idx != -1) {
        globalRegisteredStudents[idx] = _matchedStudent!;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saving profile...')));
      await saveRegisteredStudents();
      await SyncService.updateStudentTargeted(_matchedStudent!);
      await _finalizeStudentLogin(_matchedStudent!);
    } else {
      // personalPassword stage
      String hashed = hashPassword(typedPin);
      RegisteredStudent? target = _matchedStudent;
      if (hasSavedStudent) {
        try {
          target = globalRegisteredStudents.firstWhere(
            (s) => s.name == savedStudentName && s.roomNo == savedStudentRoom,
          );
        } catch (e) {}
        if (target == null) {
          // Fallback: If global list hasn't loaded yet, fetch directly!
          try {
            final snap = await FirebaseDatabase.instance
                .ref('hostelData_$globalHostelMode/students')
                .get();
            if (snap.exists && snap.value != null) {
              var studentsData = snap.value;
              var studentsList = studentsData is List
                  ? studentsData
                  : (studentsData is Map ? studentsData.values : []);
              for (var s in studentsList) {
                if (s != null) {
                  var st = RegisteredStudent.fromJson(
                    Map<String, dynamic>.from(s),
                  );
                  if (st.name == savedStudentName &&
                      st.roomNo == savedStudentRoom) {
                    target = st;
                    break;
                  }
                }
              }
            }
          } catch (e) {}
        }
      }
      // Check if student still exists (was deleted by Admin)
      if (target == null) {
        _clearSavedStudent();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is not registered. Please contact Admin.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Live verification against Firebase to prevent logging in with stale local cache
      final RegisteredStudent validatedTarget = target;
      try {
        final snap = await FirebaseDatabase.instance
            .ref('hostelData_$globalHostelMode/students')
            .get();
        if (snap.exists && snap.value != null) {
          bool foundInCloud = false;
          var studentsData = snap.value;
          var studentsList = studentsData is List
              ? studentsData
              : (studentsData is Map ? studentsData.values : []);
          for (var s in studentsList) {
            if (s != null) {
              var st = RegisteredStudent.fromJson(
                Map<String, dynamic>.from(s),
              );
              if (st.name == validatedTarget.name && st.roomNo == validatedTarget.roomNo) {
                target = st;
                foundInCloud = true;
                break;
              }
            }
          }
          if (!foundInCloud) {
            target = null;
          }
        }
      } catch (e) {}

      if (target == null) {
        _clearSavedStudent();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is not registered. Please contact Admin.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (target.pin == typedPin || target.pin == hashed) {
        if (target.pin == typedPin) {
          target.pin = hashed;
          int idx = globalRegisteredStudents.indexWhere(
            (s) => s.name == target!.name && s.roomNo == target.roomNo,
          );
          if (idx != -1) globalRegisteredStudents[idx] = target;
          await saveRegisteredStudents();
          await SyncService.updateStudentTargeted(target);
        }
        await _finalizeStudentLogin(target);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid Password')));
      }
    }
  }

  Future<void> _finalizeStudentLogin(RegisteredStudent student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_student_name', student.name);
    await prefs.setString('last_student_room', student.roomNo);
    await prefs.setString('last_student_photo', student.photoUrl ?? '');
    await prefs.setString('userType', 'student');
    await prefs.setString('hostelMode', globalHostelMode);
    await prefs.setString('identifier', student.name);
    await prefs.setString('photoPath', student.photoUrl ?? '');
    await prefs.setString(
      'extraInfo',
      student.roomNo,
    ); // CRITICAL FIX: Restart streams for the correct hostel mode before navigating
    globalStudentSuffix = "_${student.roomNo}_${student.name}";
    await SyncService.switchMode(globalHostelMode);
    await NotificationService.saveToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboardScreen(
          photoUrl: student.photoUrl,
          name: student.name,
          roomNo: student.roomNo,
        ),
      ),
    );
  }

  Future<void> _finalizeAdminLogin(AdminUser admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_admin_phone', admin.phone);
    await prefs.setString('last_admin_name', admin.name);
    await prefs.setString('last_admin_photo', admin.photoUrl ?? '');
    await prefs.setString('last_admin_scope', admin.hostelScope);
    cachedAdminScope = admin.hostelScope;
    globalStudentSuffix = null;
    await prefs.setString('userType', 'admin');
    String targetMode = admin.hostelScope.trim().toLowerCase() == 'girls'
        ? 'girls'
        : (admin.hostelScope.trim().toLowerCase() == 'boys' ? 'boys' : globalHostelMode);
    await prefs.setString('hostelMode', targetMode);
    await prefs.setString('identifier', admin.phone);
    await prefs.setString('photoPath', admin.photoUrl ?? '');
    await prefs.setString(
      'extraInfo',
      admin.name,
    ); // CRITICAL FIX: Restart streams for the correct hostel mode before navigating
    await SyncService.switchMode(targetMode);
    await NotificationService.saveToken();
    final roleDisplayName = getAdminRoleDisplayName(admin.phone);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Welcome! Logged in as $roleDisplayName",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: brandGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDashboardScreen(
          photoUrl: admin.photoUrl,
          name: admin.name,
          phone: admin.phone,
        ),
      ),
    );
  }

  Widget _buildStudentPortal() {
    return Container(
      key: const ValueKey("UnifiedLogin"),
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
                Icon(Icons.login, color: brandGreen, size: 22),
                SizedBox(width: 10),
                Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: brandDark,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 28,
            ), // === STAGE: IDENTIFIER (Email or Mobile) ===
            if (_authStage == AuthStage.identifier &&
                !hasSavedStudent &&
                !hasSavedAdmin) ...[
              const Text(
                "Email",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: brandDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter email id",
                  prefixIcon: const Icon(
                    Icons.account_circle_outlined,
                    color: brandGray,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: brandInputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifyingEmail ? null : _verifyIdentifierStage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isVerifyingEmail
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Next",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ], // === STAGE: ADMIN EMAIL VERIFICATION (First-time Staff Login) ===
            if (_authStage == AuthStage.adminEmail && _matchedAdmin != null) ...[
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: brandGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: brandGreen.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        getAdminRoleDisplayName(_matchedAdmin!.phone),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: brandGreen,
                        ),
                      ),
                    ),
                    if (_matchedAdmin!.name.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _matchedAdmin!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: brandDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Icon(Icons.mark_email_read_outlined, color: brandGreen, size: 48),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Email Verification",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: brandDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  "Verify your registered email to set up your password",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: brandGray),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Registered Email (Locked)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: brandDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: brandInputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: brandGreen, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _matchedAdmin!.email.isNotEmpty ? _matchedAdmin!.email : "No email registered",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: brandDark,
                        ),
                      ),
                    ),
                    const Icon(Icons.lock_outline, color: brandGray, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButton("Send OTP", () async {
                if (_matchedAdmin!.email.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No email registered for this staff account. Please contact Super Admin.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                setState(() => _isVerifyingEmail = true);
                Map<String, dynamic> res = await EmailOtpService.sendOtp(_matchedAdmin!.email.trim());
                setState(() => _isVerifyingEmail = false);
                if (res['success'] == true) {
                  bool verified = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => _OtpVerificationDialog(
                      email: _matchedAdmin!.email.trim(),
                      autoSend: false,
                    ),
                  ) ?? false;
                  if (verified) {
                    setState(() {
                      _authStage = AuthStage.newPassword;
                      adminPhotoUrl = _matchedAdmin!.photoUrl;
                      _studentPinController.clear();
                      _studentRePinController.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email verified! Please create your password.'),
                        backgroundColor: brandGreen,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message']?.toString() ?? 'Failed to send OTP.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }),
              const SizedBox(height: 12),
              _buildBackButton(),
            ], // === STAGE: PERSONAL PASSWORD / NEW PASSWORD / QUICK LOGIN ===
            if (_authStage == AuthStage.personalPassword ||
                _authStage == AuthStage.newPassword ||
                hasSavedStudent ||
                hasSavedAdmin) ...[
              Center(
                child: Column(
                  children: [
                    if (_authStage == AuthStage.newPassword) ...[
                      GestureDetector(
                        onTap: () => _pickImage(true),
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                shape: BoxShape.circle,
                                image:
                                    (studentPhotoUrl != null &&
                                        studentPhotoUrl!.isNotEmpty &&
                                        getSafeImageProvider(studentPhotoUrl!) != null)
                                    ? DecorationImage(
                                        image: getSafeImageProvider(studentPhotoUrl!)!,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child:
                                  (studentPhotoUrl == null ||
                                      studentPhotoUrl!.isEmpty)
                                  ? const Icon(
                                      Icons.camera_alt_outlined,
                                      color: brandGreen,
                                      size: 38,
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
                                  color: brandGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3.0,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Upload Photo",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: brandGray,
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: brandInputBg,
                          image: (() {
                            String? photo = _isAdminFlow
                                ? adminPhotoUrl
                                : (studentPhotoUrl ?? savedStudentPhoto);
                            final provider = getSafeImageProvider(photo);
                            return (provider != null)
                                ? DecorationImage(
                                    image: provider,
                                    fit: BoxFit.cover,
                                  )
                                : null;
                          })(),
                        ),
                        child: (() {
                          String? photo = _isAdminFlow
                              ? adminPhotoUrl
                              : (studentPhotoUrl ?? savedStudentPhoto);
                          return (photo == null || photo.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  color: brandGray,
                                  size: 32,
                                )
                              : null;
                        })(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_authStage == AuthStage.newPassword &&
                        !_isAdminFlow &&
                        _matchedStudent != null) ...[
                      Text(
                        _matchedStudent!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: brandDark,
                        ),
                      ),
                      Text(
                        "Room: ${_matchedStudent!.roomNo}",
                        style: const TextStyle(fontSize: 14, color: brandGray),
                      ),
                    ] else if (_isAdminFlow || hasSavedAdmin) ...[
                      Builder(
                        builder: (context) {
                          final targetPhone = _matchedAdmin?.phone ?? (hasSavedAdmin ? (savedAdminPhone ?? '') : '');
                          String roleTitle = '';
                          if (_matchedAdmin != null) {
                            if (globalRoles.containsKey(_matchedAdmin!.role) && globalRoles[_matchedAdmin!.role]!.name.isNotEmpty) {
                              roleTitle = globalRoles[_matchedAdmin!.role]!.name;
                            } else {
                              final normRole = _matchedAdmin!.role.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                              if (globalRoles.containsKey(normRole) && globalRoles[normRole]!.name.isNotEmpty) {
                                roleTitle = globalRoles[normRole]!.name;
                              }
                            }
                          }
                          if (roleTitle.isEmpty && targetPhone.isNotEmpty) {
                            roleTitle = getAdminRoleDisplayName(targetPhone);
                          }
                          if (roleTitle.isEmpty) roleTitle = 'Admin';
                          final userName = _matchedAdmin?.name ?? (hasSavedAdmin ? (savedAdminName ?? '') : '');
                          String adminScope = (_matchedAdmin?.hostelScope ??
                                  cachedAdminScope ??
                                  (targetPhone.isNotEmpty ? getAdminHostelScope(targetPhone) : ''))
                              .trim()
                              .toLowerCase();
                          String scopeBadgeText = 'Boys / Girls Hostel';
                          if (adminScope == 'boys') scopeBadgeText = 'Boys Hostel';
                          if (adminScope == 'girls') scopeBadgeText = 'Girls Hostel';

                          return Column(
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: brandGreen.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: brandGreen.withValues(alpha: 0.25)),
                                    ),
                                    child: Text(
                                      roleTitle,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: brandGreen,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.25)),
                                    ),
                                    child: Text(
                                      scopeBadgeText,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (userName.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: brandDark,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      Text(
                        hasSavedStudent
                            ? "Room: ${savedStudentRoom ?? 'Unknown'}"
                            : (selectedRoom != null
                                  ? "Room: $selectedRoom"
                                  : ""),
                        style: const TextStyle(fontSize: 14, color: brandGray),
                      ),
                      Text(
                        hasSavedStudent
                            ? (savedStudentName ?? "Student")
                            : (selectedStudentName ?? "Student"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: brandDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Password",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: brandDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentPinController,
                obscureText: !isStudentPinVisible,
                onChanged: (val) => setState(() {}),
                maxLength: 16,
                decoration: InputDecoration(
                  hintText: _authStage == AuthStage.newPassword
                      ? "Create password (8-16 chars)"
                      : "Enter password",
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: brandGray,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isStudentPinVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: brandGray,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => isStudentPinVisible = !isStudentPinVisible,
                    ),
                  ),
                  filled: true,
                  fillColor: brandInputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  counterText: "",
                ),
              ),
              if (_authStage == AuthStage.newPassword) ...[
                const SizedBox(height: 6),
                _buildPasswordHints(_studentPinController.text),
                const SizedBox(height: 16),
                const Text(
                  "Confirm Password",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: brandDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _studentRePinController,
                  obscureText: !isStudentRePinVisible,
                  onChanged: (val) => setState(() {}),
                  maxLength: 16,
                  decoration: InputDecoration(
                    hintText: "Re-enter password",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: brandGray,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isStudentRePinVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: brandGray,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => isStudentRePinVisible = !isStudentRePinVisible,
                      ),
                    ),
                    filled: true,
                    fillColor: brandInputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    counterText: "",
                  ),
                ),
              ],
              if (_authStage == AuthStage.personalPassword ||
                  hasSavedStudent ||
                  hasSavedAdmin) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _handleForgotPassword(
                      hasSavedStudent || (!_isAdminFlow && !hasSavedAdmin),
                    ),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: brandGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildActionButton(
                _authStage == AuthStage.newPassword
                    ? "Complete Registration"
                    : "Login",
                _handleUnifiedAction,
              ),
              const SizedBox(height: 12),
              _buildBackButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isVerifyingEmail ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isVerifyingEmail
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          if (hasSavedStudent) _clearSavedStudent();
          if (hasSavedAdmin) _clearSavedAdmin();
          setState(() {
            _authStage = AuthStage.identifier;
            _matchedStudent = null;
            _matchedAdmin = null;
            _isAdminFlow = false;
            _studentPinController.clear();
            _studentRePinController.clear();
            _studentEmailController.clear();
            _adminEmailController.clear();
            studentPhotoUrl = null;
            adminPhotoUrl = null;
          });
        },
        child: const Text(
          "← Go back to login / Switch user",
          style: TextStyle(
            color: brandGray,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordHints(String password) {
    bool hasLength = password.length >= 8 && password.length <= 16;
    bool hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    Widget hint(String text, bool ok) => Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.circle_outlined,
          size: 14,
          color: ok ? Colors.green : brandGray,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: ok ? Colors.green : brandGray),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hint("8-16 characters", hasLength),
        hint("At least 1 uppercase letter", hasUpper),
        hint("At least 1 number", hasNumber),
        hint("At least 1 special character (!@#\$%^&*)", hasSpecial),
      ],
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
                Icon(Icons.shield_outlined, color: brandGreen, size: 22),
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
                            color: const Color(0xFFFFF7ED),
                            shape: BoxShape.circle,
                            image:
                                (adminPhotoUrl != null &&
                                    adminPhotoUrl!.isNotEmpty &&
                                    getSafeImageProvider(adminPhotoUrl!) != null)
                                ? DecorationImage(
                                    image: getSafeImageProvider(adminPhotoUrl!)!,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              (adminPhotoUrl == null || adminPhotoUrl!.isEmpty)
                              ? const Icon(
                                  Icons.person_outline,
                                  color: brandGreen,
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
                              color: brandGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: brandGreen.withOpacity(0.3),
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
              Center(
                child: Text(
                  savedAdminName ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: brandDark,
                  ),
                ),
              ),
              Center(
                child: Text(
                  "Phone: ${savedAdminPhone ?? ''}",
                  style: const TextStyle(fontSize: 14, color: brandGray),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: brandGreen.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        "Role: ${getAdminRoleDisplayName(savedAdminPhone ?? '')}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: brandGreen,
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final s = (savedAdminPhone != null ? getAdminHostelScope(savedAdminPhone!) : (cachedAdminScope ?? '')).trim().toLowerCase();
                        String sText = "Boys / Girls Hostel";
                        if (s == 'boys') sText = "Boys Hostel";
                        if (s == 'girls') sText = "Girls Hostel";
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            sText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Please enter your email'
                              : null,
                          decoration: InputDecoration(
                            hintText: "Enter your email",
                            hintStyle: TextStyle(
                              color: brandGray.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              _adminEmailVerified
                                  ? Icons.verified
                                  : Icons.email_outlined,
                              color: _adminEmailVerified
                                  ? Colors.green
                                  : brandGray,
                              size: 22,
                            ),
                            filled: true,
                            fillColor: _adminEmailVerified
                                ? Colors.green.shade50
                                : brandInputBg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _adminEmailVerified
                                    ? Colors.green
                                    : brandGreen,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: brandDark,
                          ),
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
                            backgroundColor: _adminEmailVerified
                                ? Colors.green
                                : brandGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: _isVerifyingEmail
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _adminEmailVerified ? "Verified ✓" : "Verify",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ], // End of hasSavedAdmin
            if (hasSavedAdmin) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _handleForgotPassword(false),
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: brandGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Builder(
                  builder: (context) {
                    String targetPhone = (hasSavedAdmin && savedAdminPhone != null && savedAdminPhone!.isNotEmpty)
                        ? savedAdminPhone!
                        : _adminMobileController.text.trim();
                    String roleTitle = targetPhone.isNotEmpty
                        ? getAdminRoleDisplayName(targetPhone)
                        : "Staff";
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Login as $roleTitle",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.login, size: 20),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (hasSavedAdmin) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('last_admin_name');
                    await prefs.remove('last_admin_photo');
                    await prefs.remove('identifier');
                    await prefs.remove('userType');
                    setState(() {
                      hasSavedAdmin = false;
                    });
                  },
                  child: const Text(
                    "Redirect to Login Page",
                    style: TextStyle(
                      color: brandGray,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
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
        DropdownButtonFormField<String>(
          isExpanded: true,
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
} // ----------------------------------------------------------------------------- // STUDENT DASHBOARD SCREEN // -----------------------------------------------------------------------------

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
  bool _isEvicting = false;
  StreamSubscription? _studentsStreamSub;
  Timer? _evictionPollTimer;
  Timer? _autoCloseStudentTimer;

  @override
  void initState() {
    super.initState();
    globalStudentSuffix = "_${widget.roomNo}_${widget.name}";
    globalSyncTrigger.addListener(_onSync); // Auto-refresh when dashboard opens
    _initDirectStudentListener();
    _startEvictionHeartbeat();

    // Auto-close check every 10 seconds to ensure instant close at scheduled time
    _autoCloseStudentTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      bool changed = false;
      if (globalEntryL && isPastLunchCloseTime()) {
        SyncService.autoCloseIfExpired('l');
        changed = true;
      }
      if (globalEntryD && isPastDinnerCloseTime()) {
        SyncService.autoCloseIfExpired('d');
        changed = true;
      }
      if (changed && mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppUpdateService.checkForUpdate(context);
      await SyncService.fetchNow();
      _verifyStudentStillExists();
      DateTime now = realTime;
      // Fetch current month first for instantaneous load
      await fetchAttendanceMonth(now.year, now.month);
      if (mounted) {
        setState(() {
          _isFetchingData = false;
        });
      }
      // Fetch past months lazily in background without blocking UI
      Future.microtask(() async {
        for (int m = now.month - 1; m >= 1; m--) {
          if (!mounted) break;
          await fetchAttendanceMonth(now.year, m);
        }
      });
    });
  }

  void _initDirectStudentListener() {
    _studentsStreamSub?.cancel();
    _studentsStreamSub = FirebaseDatabase.instance
        .ref('hostelData_$globalHostelMode/students')
        .onValue
        .listen((event) {
          _checkSnapshotForEviction(event.snapshot);
        }, onError: (e) {
          print("Students stream error: $e");
        });
  }

  void _startEvictionHeartbeat() {
    _evictionPollTimer?.cancel();
    // 60-second fallback poll ensures auto-logout check without flooding Firebase under 500 users
    _evictionPollTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (_isEvicting || !mounted) return;
      try {
        final snap = await FirebaseDatabase.instance
            .ref('hostelData_$globalHostelMode/students')
            .get();
        if (snap.exists) {
          _checkSnapshotForEviction(snap);
        } else {
          _executeInstantAutoLogout();
        }
      } catch (e) {}
    });
  }

  void _checkSnapshotForEviction(DataSnapshot snap) {
    if (_isEvicting || !mounted) return;
    bool foundCurrentStudent = false;

    if (snap.value != null) {
      var raw = snap.value;
      var list = raw is List ? raw : (raw is Map ? raw.values : []);
      for (var s in list) {
        if (s != null && s is Map) {
          String sName = (s['name'] ?? '').toString().trim().toLowerCase();
          String sRoom = (s['roomNo'] ?? '').toString().trim().toLowerCase();
          if (sName == widget.name.trim().toLowerCase() &&
              sRoom == widget.roomNo.trim().toLowerCase()) {
            foundCurrentStudent = true;
            break;
          }
        }
      }
    }

    if (!foundCurrentStudent) {
      _executeInstantAutoLogout();
    }
  }

  @override
  void dispose() {
    _studentsStreamSub?.cancel();
    _evictionPollTimer?.cancel();
    _autoCloseStudentTimer?.cancel();
    globalSyncTrigger.removeListener(_onSync);
    _lunchMsgTimer?.cancel();
    _dinnerMsgTimer?.cancel();
    super.dispose();
  }

  void _onSync() {
    _verifyStudentStillExists();
    if (mounted) setState(() {});
  }

  void _verifyStudentStillExists() async {
    if (_isEvicting || !mounted) return;
    if (!SyncService._hasDownloadedOnce) return;

    bool stillExists = globalRegisteredStudents.any(
      (s) =>
          s.name.trim().toLowerCase() == widget.name.trim().toLowerCase() &&
          s.roomNo.trim().toLowerCase() == widget.roomNo.trim().toLowerCase(),
    );

    if (!stillExists) {
      _executeInstantAutoLogout();
    }
  }

  void _executeInstantAutoLogout() async {
    if (_isEvicting) return;
    _isEvicting = true;

    _studentsStreamSub?.cancel();
    _evictionPollTimer?.cancel();
    SyncService.cancelAllStreams();
    globalStudentSuffix = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userType');
    await prefs.remove('identifier');
    await prefs.remove('extraInfo');
    await prefs.remove('photoPath');
    await prefs.remove('last_student_name');
    await prefs.remove('last_student_room');
    await prefs.remove('last_student_photo');

    // Immediately redirect to LoginScreen!
    final nav = globalNavigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }

    // Show English alert message on Login Screen
    Future.delayed(const Duration(milliseconds: 300), () {
      final navCtx = globalNavigatorKey.currentContext;
      if (navCtx != null) {
        showDialog(
          context: navCtx,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Access Revoked', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Your account has been removed by the Admin.\nPlease contact the Admin to register again.',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
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
    realTime.year,
    realTime.month,
  );
  Widget _buildHomeTab() {
    DateTime now = realTime;
    String rawKey = "${now.year}-${now.month}-${now.day}_${widget.roomNo}_${widget.name}";
    String key = attendanceSafeKey(rawKey);
    DailyRecord todayRecord = globalAttendanceMap[key] ?? globalAttendanceMap[rawKey] ?? DailyRecord();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(Icons.restaurant, color: brandGreen),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Today's Attendance",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: brandDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}",
                        style: const TextStyle(
                          color: brandGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 32,
                ), // LUNCH SECTION - only show when entry is ON and not expired, OR if student already marked today
                if ((globalEntryL && !isPastLunchCloseTime()) || todayRecord.l.isNotEmpty) ...[
                  const Text(
                    "Lunch",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: brandDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (todayRecord.l.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (todayRecord.l == 'P'
                                    ? Colors.green
                                    : Colors.redAccent)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            todayRecord.l == 'P'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: todayRecord.l == 'P'
                                ? Colors.green
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              todayRecord.l == 'P'
                                  ? "Attendance marked! (P)"
                                  : "Meal Skipped (A)",
                              style: TextStyle(
                                color: todayRecord.l == 'P'
                                    ? Colors.green
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (todayRecord.l == 'P')
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MealPassScreen(
                                      mealName: 'Lunch',
                                      photoUrl: widget.photoUrl,
                                      name: widget.name,
                                      roomNo: widget.roomNo,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.badge, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      "Show Pass",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (todayRecord.l == 'A' && (globalEntryL && !isPastLunchCloseTime()))
                            TextButton(
                              onPressed: () async {
                                setState(() {
                                  todayRecord.l = '';
                                });
                                await SyncService.pushAttendance(
                                  key,
                                  todayRecord,
                                );
                              },
                              child: const Text(
                                "Undo",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    )
                  else if (todayRecord.l.isEmpty && (globalEntryL && !isPastLunchCloseTime()))
                    Column(
                      children: [
                        SwipeToConfirm(
                          text: "Swipe for Lunch",
                          onConfirm: () async {
                            setState(() {
                              globalAttendanceMap.putIfAbsent(
                                key,
                                () => DailyRecord(),
                              );
                              globalAttendanceMap[key]!.l = 'P';
                              globalAttendanceMap[key]!.lTime = formatTimeOfDay(realTime.hour, realTime.minute);
                              _lunchMsgVisible = true;
                            });
                            await SyncService.pushAttendance(
                              key,
                              globalAttendanceMap[key]!,
                            );
                            _lunchMsgTimer?.cancel();
                            _lunchMsgTimer = Timer(
                              const Duration(minutes: 3),
                              () {
                                if (mounted)
                                  setState(() => _lunchMsgVisible = false);
                              },
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MealPassScreen(
                                  mealName: 'Lunch',
                                  photoUrl: widget.photoUrl,
                                  name: widget.name,
                                  roomNo: widget.roomNo,
                                ),
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            setState(() {
                              globalAttendanceMap.putIfAbsent(
                                key,
                                () => DailyRecord(),
                              );
                              globalAttendanceMap[key]!.l = 'A';
                              _lunchMsgVisible = true;
                            });
                            await SyncService.pushAttendance(
                              key,
                              globalAttendanceMap[key]!,
                            );
                            _lunchMsgTimer?.cancel();
                            _lunchMsgTimer = Timer(
                              const Duration(minutes: 3),
                              () {
                                if (mounted)
                                  setState(() => _lunchMsgVisible = false);
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            "Skip Meal",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                ], // DINNER SECTION - only show when entry is ON and not expired, OR if student already marked today
                if ((globalEntryD && !isPastDinnerCloseTime()) || todayRecord.d.isNotEmpty) ...[
                  const Text(
                    "Dinner",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: brandDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (todayRecord.d.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (todayRecord.d == 'P'
                                    ? Colors.green
                                    : Colors.redAccent)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            todayRecord.d == 'P'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: todayRecord.d == 'P'
                                ? Colors.green
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              todayRecord.d == 'P'
                                  ? "Attendance marked! (P)"
                                  : "Meal Skipped (A)",
                              style: TextStyle(
                                color: todayRecord.d == 'P'
                                    ? Colors.green
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (todayRecord.d == 'P')
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MealPassScreen(
                                      mealName: 'Dinner',
                                      photoUrl: widget.photoUrl,
                                      name: widget.name,
                                      roomNo: widget.roomNo,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.badge, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      "Show Pass",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (todayRecord.d == 'A' && (globalEntryD && !isPastDinnerCloseTime()))
                            TextButton(
                              onPressed: () async {
                                setState(() {
                                  todayRecord.d = '';
                                });
                                await SyncService.pushAttendance(
                                  key,
                                  todayRecord,
                                );
                              },
                              child: const Text(
                                "Undo",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    )
                  else if (todayRecord.d.isEmpty && (globalEntryD && !isPastDinnerCloseTime()))
                    Column(
                      children: [
                        SwipeToConfirm(
                          text: "Swipe for Dinner",
                          onConfirm: () async {
                            setState(() {
                              globalAttendanceMap.putIfAbsent(
                                key,
                                () => DailyRecord(),
                              );
                              globalAttendanceMap[key]!.d = 'P';
                              globalAttendanceMap[key]!.dTime = formatTimeOfDay(realTime.hour, realTime.minute);
                              _dinnerMsgVisible = true;
                            });
                            await SyncService.pushAttendance(
                              key,
                              globalAttendanceMap[key]!,
                            );
                            _dinnerMsgTimer?.cancel();
                            _dinnerMsgTimer = Timer(
                              const Duration(minutes: 3),
                              () {
                                if (mounted)
                                  setState(() => _dinnerMsgVisible = false);
                              },
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MealPassScreen(
                                  mealName: 'Dinner',
                                  photoUrl: widget.photoUrl,
                                  name: widget.name,
                                  roomNo: widget.roomNo,
                                ),
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            setState(() {
                              globalAttendanceMap.putIfAbsent(
                                key,
                                () => DailyRecord(),
                              );
                              globalAttendanceMap[key]!.d = 'A';
                              _dinnerMsgVisible = true;
                            });
                            await SyncService.pushAttendance(
                              key,
                              globalAttendanceMap[key]!,
                            );
                            _dinnerMsgTimer?.cancel();
                            _dinnerMsgTimer = Timer(
                              const Duration(minutes: 3),
                              () {
                                if (mounted)
                                  setState(() => _dinnerMsgVisible = false);
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            "Skip Meal",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                ], // Show "No entry active" when both are OFF
                if (!globalEntryL && !globalEntryD)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        "No mess entry is currently active.",
                        style: TextStyle(
                          color: brandGray,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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

  Widget _buildStatBox(
    String title,
    String value,
    Color color, {
    String? subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
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
    String paymentKey =
        "$currentYear-${currentMonth}_${widget.roomNo}_${widget.name}";
    int paidAmount = globalMonthlyPaid[paymentKey] ?? 0;
    int dueAmount = payableBill - paidAmount;
    if (dueAmount < 0) dueAmount = 0;
    String monthName = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
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
                    Icon(Icons.bar_chart, color: brandGreen),
                    SizedBox(width: 8),
                    Text(
                      "Attendance",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        size: 16,
                        color: brandGreen,
                      ),
                      onPressed: () => setState(() {
                        _attendanceMonth = DateTime(
                          _attendanceMonth.year,
                          _attendanceMonth.month - 1,
                          1,
                        );
                      }),
                    ),
                    Text(
                      "$monthName $currentYear",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: brandGreen,
                      ),
                      onPressed: () => setState(() {
                        _attendanceMonth = DateTime(
                          _attendanceMonth.year,
                          _attendanceMonth.month + 1,
                          1,
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    "Present",
                    "$presentDays Days",
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatBox(
                    "Absent",
                    "$absentDays Days",
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    "Payable Bill",
                    "₹$payableBill",
                    brandGreen,
                    subtext: "(Min 22-day rule)",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatBox(
                    "Actual Bill",
                    "₹$actualBill",
                    brandDark,
                    subtext: "(Real cost)",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    "Paid",
                    "₹$paidAmount",
                    Colors.green,
                    subtext: "(Amount Paid)",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatBox(
                    "Due (Pending)",
                    "₹$dueAmount",
                    Colors.redAccent,
                    subtext: "(To be paid)",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
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
                icon: const Icon(Icons.list_alt, color: Colors.white),
                label: const Text(
                  "View Full Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicPolls() {
    String studentKey = SyncService.pollSafeKey(
      "${widget.roomNo}_${widget.name}",
    );
    final nowMs = realTime.millisecondsSinceEpoch;
    final now = realTime; // Filter active polls
    final polls = SyncService.dynamicPolls.values.where((p) {
      bool isLocked = nowMs > p.endTime || !p.isActive;
      if (!isLocked) return true;
      // Keep closed polls visible to students for 24 hours after end time
      const twentyFourHours = 24 * 60 * 60 * 1000;
      return (nowMs - p.endTime) < twentyFourHours;
    }).toList()..sort((a, b) => b.startTime.compareTo(a.startTime));
    if (polls.isEmpty) {
      return Card(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              "No polls are currently active.",
              style: TextStyle(color: brandGray, fontSize: 16),
            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.poll, color: brandGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: brandDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Time: ${TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(p.startTime)).format(context)} - ${TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(p.endTime)).format(context)}",
                  style: const TextStyle(
                    color: brandGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Divider(height: 24),
                ...p.options.map((opt) {
                  int optVotes = p.votes.values.where((v) => v == opt).length;
                  double percent = totalVotes == 0 ? 0 : optVotes / totalVotes;
                  bool amI = myVote == opt;
                  return InkWell(
                    onTap: isLocked
                        ? null
                        : () async {
                            if (realTime.millisecondsSinceEpoch >
                                    p.endTime ||
                                !p.isActive) {
                              setState(() {});
                              return;
                            }
                            if (amI) {
                              await SyncService.removeVoteDynamicPoll(
                                p.id,
                                studentKey,
                              );
                            } else {
                              await SyncService.voteDynamicPoll(
                                p.id,
                                studentKey,
                                opt,
                              );
                            }
                            setState(() {});
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
                                color: amI
                                    ? brandGreen.withOpacity(0.3)
                                    : Colors.blue.withOpacity(0.3),
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
                                    Text(
                                      opt,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isLocked ? brandGray : brandDark,
                                      ),
                                    ),
                                    if (amI)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: brandGreen,
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  "${(percent * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(color: brandDark),
                                ),
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
                    Text(
                      "Total Votes: $totalVotes",
                      style: const TextStyle(color: brandGray, fontSize: 12),
                    ),
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Poll Closed (Final Result)",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (myVote != null)
                      Text(
                        "Your Vote: $myVote",
                        style: const TextStyle(
                          color: brandGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
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
                    backgroundColor: Color(0xFFFFF7ED),
                    child: Icon(Icons.notifications, color: brandGreen),
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
                          color: brandGreen,
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
                      }); // Save locally only - don't push to Firebase
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList(
                        'hiddenNotices',
                        globalStudentHiddenNotices.toList(),
                      );
                    },
                  ),
                ),
              );
            },
          );
  }

  void _onLogout() async {
    globalStudentSuffix = null;
    SyncService.cancelAllStreams();
    globalStudentSuffix = null;
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
            backgroundColor: brandGreen,
            title: const Text(
              "Student Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text("Refreshing all data..."),
                        ],
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  DateTime now = realTime;
                  String monthKey = "${globalHostelMode}_${now.year}-${now.month}";
                  _fetchedApiMonths.remove(monthKey);
                  await fetchAttendanceMonth(now.year, now.month);
                  await SyncService.fetchNow();
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("App refreshed successfully! 🔄"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: brandGreen),
                  accountName: Text(
                    widget.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text("Room: ${widget.roomNo}"),
                  currentAccountPicture: CircleAvatar(
                    child:
                        (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                        ? ClipOval(
                            child: Image.network(
                              widget.photoUrl!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: Colors.white),
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
                  leading: const Icon(
                    Icons.feedback_outlined,
                    color: brandDark,
                  ),
                  title: Text(
                    'Mess Complaints (${globalHostelMode == 'boys' ? 'Boys' : 'Girls'})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutDevelopersScreen(),
                      ),
                    );
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
                      child:
                          (widget.photoUrl != null &&
                              widget.photoUrl!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                widget.photoUrl!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
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
                            maxLines: 3,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: brandGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Room: ${widget.roomNo}",
                              style: const TextStyle(
                                color: brandGreen,
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
              ), // Main Body Content
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
                  globalStudentLastViewedNotices = realTime;
                }
              });
            },
            selectedItemColor: brandGreen,
            unselectedItemColor: brandGray,
            backgroundColor: Colors.white,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
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
} // ----------------------------------------------------------------------------- // LONG LEAVE SCREEN (UNDER CONSTRUCTION) // -----------------------------------------------------------------------------

class LongLeaveScreen extends StatelessWidget {
  const LongLeaveScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        backgroundColor: brandGreen,
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
                  color: brandGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 72,
                  color: brandGreen,
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
} // ----------------------------------------------------------------------------- // ADMIN DASHBOARD SCREEN // -----------------------------------------------------------------------------

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
  bool _isEvicting = false;
  StreamSubscription? _adminsStreamSub;
  StreamSubscription? _rolesStreamSub;
  Timer? _adminEvictionPollTimer;
  Timer? _autoCloseCheckTimer;
  bool _showAllDues = false;

  @override
  void initState() {
    super.initState();
    globalStudentSuffix = null;
    globalSyncTrigger.addListener(_onSync); // Auto-refresh when dashboard opens
    _initDirectAdminListener();
    _initRolesListener();
    _startAdminEvictionHeartbeat();
    _autoCloseCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAutoClose(),
    );

    final initialScope = getAdminHostelScope(widget.phone);
    if (initialScope == 'boys' && globalHostelMode != 'boys') {
      SyncService.switchMode('boys');
    } else if (initialScope == 'girls' && globalHostelMode != 'girls') {
      SyncService.switchMode('girls');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppUpdateService.checkForUpdate(context);
      await SyncService.fetchNow();
      _verifyAdminStillExists();
      DateTime now = realTime;
      // Fetch current month first so dashboard data displays instantly
      await fetchAttendanceMonth(now.year, now.month);
      if (mounted) {
        setState(() {
          _isFetchingData = false;
        });
      }
      // Fetch past months lazily in background for dues and reports
      Future.microtask(() async {
        for (int m = now.month - 1; m >= 1; m--) {
          if (!mounted) break;
          await fetchAttendanceMonth(now.year, m);
          if (mounted) setState(() {});
        }
      });
    });
  }

  void _initRolesListener() {
    _rolesStreamSub?.cancel();
    _rolesStreamSub = FirebaseDatabase.instance.ref('roles').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        var raw = event.snapshot.value;
        if (raw is Map) {
          raw.forEach((k, v) {
            if (v is Map) {
              globalRoles[k.toString()] = RoleDefinition.fromJson(
                k.toString(),
                Map<String, dynamic>.from(v),
              );
            }
          });
          if (mounted) setState(() {});
        }
      }
    }, onError: (e) {
      print("Roles stream error: $e");
    });
  }

  void _initDirectAdminListener() {
    _adminsStreamSub?.cancel();
    _adminsStreamSub = FirebaseDatabase.instance
        .ref('hostelData_$globalHostelMode/admins')
        .onValue
        .listen((event) {
          _checkAdminSnapshotForEviction(event.snapshot);
        }, onError: (e) {
          print("Admins stream error: $e");
        });
  }

  void _startAdminEvictionHeartbeat() {
    _adminEvictionPollTimer?.cancel();
    // 60-second fallback poll ensures auto-logout check without flooding Firebase under 500 users
    _adminEvictionPollTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (_isEvicting || !mounted) return;
      try {
        final snap = await FirebaseDatabase.instance
            .ref('hostelData_$globalHostelMode/admins')
            .get();
        if (snap.exists) {
          _checkAdminSnapshotForEviction(snap);
        } else {
          _executeInstantAdminAutoLogout();
        }
      } catch (e) {}
    });
  }

  void _checkAdminSnapshotForEviction(DataSnapshot snap) {
    if (_isEvicting || !mounted) return;
    bool foundCurrentAdmin = false;

    if (snap.value != null) {
      var raw = snap.value;
      var list = raw is List ? raw : (raw is Map ? raw.values : []);
      for (var a in list) {
        if (a != null && a is Map) {
          String aPhone = (a['phone'] ?? '').toString().trim();
          if (aPhone == widget.phone.trim()) {
            foundCurrentAdmin = true;
            String updatedScope = (a['hostelScope'] ?? 'both').toString().trim().toLowerCase();
            String updatedRole = (a['role'] ?? 'admin').toString().trim();
            cachedAdminScope = updatedScope;
            int idx = globalAdmins.indexWhere((x) => x.phone.trim() == widget.phone.trim());
            if (idx != -1) {
              globalAdmins[idx].hostelScope = updatedScope;
              globalAdmins[idx].role = updatedRole;
            }
            if (updatedScope == 'boys' && globalHostelMode != 'boys') {
              SyncService.switchMode('boys');
            } else if (updatedScope == 'girls' && globalHostelMode != 'girls') {
              SyncService.switchMode('girls');
            }
            if (mounted) setState(() {});
            break;
          }
        }
      }
    }

    if (!foundCurrentAdmin) {
      _executeInstantAdminAutoLogout();
    }
  }

  @override
  void dispose() {
    _adminsStreamSub?.cancel();
    _rolesStreamSub?.cancel();
    _adminEvictionPollTimer?.cancel();
    _autoCloseCheckTimer?.cancel();
    _liveSwipeSearchCtrl.dispose();
    globalSyncTrigger.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    _verifyAdminStillExists();
    final scope = getAdminHostelScope(widget.phone);
    if (scope == 'boys' && globalHostelMode != 'boys') {
      SyncService.switchMode('boys');
    } else if (scope == 'girls' && globalHostelMode != 'girls') {
      SyncService.switchMode('girls');
    }
    if (mounted) setState(() {});
  }

  void _verifyAdminStillExists() async {
    if (_isEvicting || !mounted) return;
    if (!SyncService._hasDownloadedOnce) return;

    bool stillExists = globalAdmins.any(
      (a) => a.phone.trim() == widget.phone.trim(),
    );

    if (!stillExists) {
      _executeInstantAdminAutoLogout();
    }
  }

  void _executeInstantAdminAutoLogout() async {
    if (_isEvicting) return;
    _isEvicting = true;

    _adminsStreamSub?.cancel();
    _adminEvictionPollTimer?.cancel();
    SyncService.cancelAllStreams();
    globalStudentSuffix = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userType');
    await prefs.remove('identifier');
    await prefs.remove('extraInfo');
    await prefs.remove('photoPath');
    await prefs.remove('last_admin_phone');
    await prefs.remove('last_admin_name');
    await prefs.remove('last_admin_photo');
    await prefs.remove('last_admin_scope');
    cachedAdminScope = null;

    final nav = globalNavigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      final navCtx = globalNavigatorKey.currentContext;
      if (navCtx != null) {
        showDialog(
          context: navCtx,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Access Revoked', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Your Admin account has been removed.\nPlease contact Super Admin.',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  List<Map<String, dynamic>>? _cachedPendingDues;
  int _lastDuesTrigger = -1;

  List<Map<String, dynamic>> _getPendingDues() {
    if (_cachedPendingDues != null && _lastDuesTrigger == globalSyncTrigger.value) {
      return _cachedPendingDues!;
    }
    List<Map<String, dynamic>> pendingList = [];
    List<String> months = [
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
          if (rec.l == 'P')
            studentMonthStats[groupKey]!['P'] =
                (studentMonthStats[groupKey]!['P']! + 1);
          if (rec.l == 'A')
            studentMonthStats[groupKey]!['A'] =
                (studentMonthStats[groupKey]!['A']! + 1);
          if (rec.d == 'P')
            studentMonthStats[groupKey]!['P'] =
                (studentMonthStats[groupKey]!['P']! + 1);
          if (rec.d == 'A')
            studentMonthStats[groupKey]!['A'] =
                (studentMonthStats[groupKey]!['A']! + 1);
        }
      }
    });
    studentMonthStats.forEach((groupKey, counts) {
      if (counts['P'] == 0 && counts['A'] == 0) return;
      List<String> parts = groupKey.split('_');
      String yearMonth = parts[0];
      String room = parts[1];
      String name = parts[2]; // Skip the current month - only show past months
      DateTime now = realTime;
      String currentMonthKey = "${now.year}-${now.month}";
      if (yearMonth == currentMonthKey) return;
      List<String> ymParts = yearMonth.split('-');
      String year = ymParts[0];
      int mIdx = int.tryParse(ymParts[1]) ?? 1;
      String monthName = months[mIdx - 1];
      int payableBill = calculatePayableBill(counts['P']!);
      int paidAmt = globalMonthlyPaid[groupKey] ?? 0;
      if (paidAmt < payableBill) {
        if (globalAdminDismissedDues.contains(groupKey)) return;
        RegisteredStudent? student;
        try {
          student = globalRegisteredStudents.firstWhere(
            (s) => s.roomNo == room && s.name == name,
          );
        } catch (e) {}
        if (student != null) {
          pendingList.add({
            'groupKey': groupKey,
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
    _cachedPendingDues = pendingList;
    _lastDuesTrigger = globalSyncTrigger.value;
    return pendingList;
  }

  int _selectedIndex = 0;
  String _liveSwipeSelectedMeal = 'l';
  String _liveSwipeSearchQuery = '';
  final TextEditingController _liveSwipeSearchCtrl = TextEditingController();

  Widget _buildAdminHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (checkAdminPermission(widget.phone, 'can_manage_meals')) ...[
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.restaurant, color: brandDark, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Quick Mess Entry",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: brandDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lunch Mess Open', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: InkWell(
                      onTap: () => _pickAutoCloseTime('l'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: brandGray),
                            const SizedBox(width: 4),
                            Text(
                              "Auto-close: ${formatTimeOfDay(globalLunchCloseHour, globalLunchCloseMinute)} (Tap to edit)",
                              style: const TextStyle(fontSize: 12, color: brandGreen, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    activeColor: brandGreen,
                    value: globalEntryL,
                    onChanged: (v) => _toggleMessEntryWithConfirmation('l', v),
                  ),
                  const Divider(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dinner Mess Open', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: InkWell(
                      onTap: () => _pickAutoCloseTime('d'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: brandGray),
                            const SizedBox(width: 4),
                            Text(
                              "Auto-close: ${formatTimeOfDay(globalDinnerCloseHour, globalDinnerCloseMinute)} (Tap to edit)",
                              style: const TextStyle(fontSize: 12, color: brandGreen, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    activeColor: brandGreen,
                    value: globalEntryD,
                    onChanged: (v) => _toggleMessEntryWithConfirmation('d', v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _buildDailyAttendanceSummaryCard(),
        const SizedBox(height: 12),
        _buildLiveSwipedSection(),
        const SizedBox(height: 12),
        ...(() {
          final allPolls = SyncService.dynamicPolls.values.toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));
          if (allPolls.isEmpty || !checkAdminPermission(widget.phone, 'can_manage_polls')) return <Widget>[const SizedBox.shrink()];
          return <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Live & Recent Polls",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: brandDark,
                    ),
                  ),
                  if (checkAdminPermission(widget.phone, 'can_manage_polls'))
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () => _showCreatePollDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("New Poll", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            ...allPolls.map<Widget>((p) {
              final bool closed =
                  !p.isActive ||
                  realTime.millisecondsSinceEpoch > p.endTime;
              final String fmtStart = TimeOfDay.fromDateTime(
                DateTime.fromMillisecondsSinceEpoch(p.startTime),
              ).format(context);
              final String fmtEnd = TimeOfDay.fromDateTime(
                DateTime.fromMillisecondsSinceEpoch(p.endTime),
              ).format(context);
              final String dateStr =
                  "${DateTime.fromMillisecondsSinceEpoch(p.startTime).day}/${DateTime.fromMillisecondsSinceEpoch(p.startTime).month}";
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.question,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: brandDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Date: $dateStr | Time: $fmtStart - $fmtEnd",
                                  style: const TextStyle(
                                    color: brandGray,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: closed ? Colors.redAccent.withValues(alpha: 0.12) : brandGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              closed ? "Closed" : "Live",
                              style: TextStyle(
                                color: closed ? Colors.redAccent : brandGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (checkAdminPermission(widget.phone, 'can_manage_polls')) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: brandDark),
                              tooltip: "Edit Poll",
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () => _showEditPollDialog(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              tooltip: "Delete Poll",
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () => _confirmDeletePoll(p),
                            ),
                          ],
                        ],
                      ),
                      const Divider(height: 20),
                      ...p.options.map((o) {
                        final int optVotes = p.votes.values.where((v) => v == o).length;
                        final double pct = p.votes.isEmpty ? 0 : optVotes / p.votes.length;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "$o: $optVotes votes (${(pct * 100).toStringAsFixed(1)}%)",
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: brandDark),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _showPollVotersDialog(p, o),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.people_alt_outlined, size: 14, color: brandGreen),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Voters ($optVotes)",
                                            style: const TextStyle(fontSize: 11, color: brandGreen, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    closed ? brandGray : brandGreen,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Votes: ${p.votes.length}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: brandGray,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: brandDark,
                                  side: BorderSide(color: brandDark.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _exportPollResultToPdf(p),
                                icon: const Icon(Icons.picture_as_pdf, size: 14, color: Colors.redAccent),
                                label: const Text("PDF", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: brandGreen,
                                  side: BorderSide(color: brandGreen.withValues(alpha: 0.4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showPollVotersDialog(p),
                                icon: const Icon(Icons.people, size: 14),
                                label: const Text("All Voters", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              if (!closed && checkAdminPermission(widget.phone, 'can_manage_polls'))
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () async {
                                    await SyncService.stopDynamicPoll(p.id);
                                    if (mounted) setState(() {});
                                  },
                                  child: const Text("End Poll", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const Divider(height: 32),
          ];
        })(),
        ...(() {
          var dues = _getPendingDues();
          if (dues.isEmpty || (!checkAdminPermission(widget.phone, 'can_students_manage') && !checkAdminPermission(widget.phone, 'can_attendance'))) return <Widget>[const SizedBox.shrink()];
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
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
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
                        if (dues.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.cleaning_services_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            tooltip: "Clear All Dues (બધા ક્લિયર કરો)",
                            onPressed: () => _showClearAllDuesDialog(dues),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_active,
                              color: Colors.redAccent,
                            ),
                            tooltip: "Send Reminders",
                            onPressed: () {
                              List<String> names = dues
                                  .map(
                                    (d) => (d['student'] as RegisteredStudent)
                                        .name,
                                  )
                                  .toList();
                              NotificationService.sendPushNotificationToSpecificStudents(
                                names,
                                "Pending Mess Bill",
                                "Please pay your pending mess bill for ${dues[0]['monthName']} ${dues[0]['year']}.",
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Reminders sent!"),
                                ),
                              );
                            },
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${dues.length} Pending",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ...((_showAllDues || dues.length <= 5 ? dues : dues.take(5)).map((due) {
                      RegisteredStudent st = due['student'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: brandGreen,
                              child:
                                  (st.photoUrl != null &&
                                      st.photoUrl!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        st.photoUrl!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                              radius: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${st.name} (Room ${st.roomNo})",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: brandDark,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${due['monthName']} ${due['year']} - Bill: ₹${due['payable']} | Paid: ₹${due['paid']}",
                                    style: const TextStyle(
                                      color: brandGray,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "₹${due['due']}",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              tooltip: "Delete / Clear Fee",
                              onPressed: () => _showClearDueDialog(due),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                    if (dues.length > 5)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showAllDues = !_showAllDues),
                          icon: Icon(_showAllDues ? Icons.expand_less : Icons.expand_more, size: 16, color: brandDark),
                          label: Text(
                            _showAllDues ? "Show Less" : "Show All (${dues.length} Students)",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandDark),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ];
        })(),
      ],
    );
  }

  void _showClearDueDialog(Map<String, dynamic> due) {
    final RegisteredStudent st = due['student'];
    final String gKey = due['groupKey'] as String;
    final int payable = due['payable'] as int;
    final int dueAmt = due['due'] as int;
    final String monthName = due['monthName'] as String;
    final String year = due['year'] as String;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Clear Pending Fee",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${st.name} (Room ${st.roomNo})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark),
            ),
            const SizedBox(height: 4),
            Text(
              "Period: $monthName $year • Pending Due: ₹$dueAmt",
              style: const TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              "How would you like to remove this entry from the dashboard?",
              style: TextStyle(fontSize: 12, color: brandGray),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: brandGray)),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                globalAdminDismissedDues.add(gKey);
                _cachedPendingDues = null;
              });
              await saveAdminDismissedDues();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${st.name}'s fee entry dismissed from dashboard."),
                    backgroundColor: brandDark,
                  ),
                );
              }
            },
            child: const Text("Dismiss / Delete", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                globalMonthlyPaid[gKey] = payable;
                _cachedPendingDues = null;
              });
              await SyncService.pushPaidTargeted(gKey, payable);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Marked as fully paid! ₹$dueAmt cleared."),
                    backgroundColor: brandGreen,
                  ),
                );
              }
            },
            child: const Text("Mark as Paid", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDuesDialog(List<Map<String, dynamic>> dues) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text(
              "Clear All Pending Dues",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to clear all ${dues.length} pending dues from the dashboard?",
          style: const TextStyle(fontSize: 13, color: brandDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: brandGray)),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                for (var d in dues) {
                  final gKey = d['groupKey'] as String;
                  globalAdminDismissedDues.add(gKey);
                }
                _cachedPendingDues = null;
              });
              await saveAdminDismissedDues();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All pending dues dismissed from dashboard!"),
                    backgroundColor: brandDark,
                  ),
                );
              }
            },
            child: const Text("Dismiss All", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              for (var d in dues) {
                final gKey = d['groupKey'] as String;
                final payable = d['payable'] as int;
                globalMonthlyPaid[gKey] = payable;
                await SyncService.pushPaidTargeted(gKey, payable);
              }
              setState(() {
                _cachedPendingDues = null;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All dues marked as paid & cleared!"),
                    backgroundColor: brandGreen,
                  ),
                );
              }
            },
            child: const Text("Mark All Paid", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showWeeklyColorScheduleDialog() {
    final now = realTime;
    final todayWeekday = now.weekday;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.palette_rounded, color: brandDark, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Meal Pass Weekly Colors",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: brandDark),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: brandDark.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "વિદ્યાર્થીઓ જ્યારે મેસ એન્ટ્રી સ્વાઇપ કરશે ત્યારે વાર મુજબ આ રંગનો પાસ દેખાશે. એડમિન/કેન્ટીન સ્ટાફે કાઉન્ટર પર આજનો કલર વેરિફાય કરવો.",
                  style: TextStyle(fontSize: 12, color: brandDark, height: 1.3),
                ),
              ),
              const SizedBox(height: 14),
              ...([1, 2, 3, 4, 5, 6, 7].map((w) {
                final t = dayPassThemes[w]!;
                final isToday = (w == todayWeekday);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isToday ? t.primaryColor.withValues(alpha: 0.12) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday ? t.primaryColor : Colors.grey.shade200,
                      width: isToday ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [t.primaryColor, t.secondaryColor],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: t.primaryColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(t.emoji, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${t.dayName} (${t.dayNameGu})",
                                  style: TextStyle(
                                    fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                                    fontSize: 14,
                                    color: isToday ? t.primaryColor : brandDark,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: brandGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "TODAY",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${t.colorName} • ${t.colorNameGu}",
                              style: TextStyle(
                                fontSize: 11,
                                color: isToday ? t.primaryColor : brandGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              })),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK / બરાબર", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditTenderPriceDialog() {
    final ctrl = TextEditingController(text: globalTenderPrice.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.currency_rupee, color: brandDark),
            SizedBox(width: 8),
            Text(
              "Custom Tender Price",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: brandDark),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Set the per-meal tender rate used for calculating total daily and monthly billing:",
                style: TextStyle(fontSize: 13, color: brandGray),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Price Per Meal (₹)",
                  prefixIcon: const Icon(Icons.currency_rupee, color: brandGreen),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: brandGray, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newP = int.tryParse(ctrl.text.trim());
              if (newP != null && newP > 0) {
                Navigator.pop(ctx);
                await SyncService.pushTenderPrice(newP);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Tender price updated to ₹$newP per meal."),
                      backgroundColor: brandGreen,
                    ),
                  );
                }
              }
            },
            child: const Text("Save Price", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAttendanceSummaryCard() {
    DateTime now = realTime;
    final students = globalRegisteredStudents.where((s) => s.isValid).toList();
    final int totalStudents = students.length;

    int lunchPresent = 0;
    int lunchAbsent = 0;
    int lunchPending = 0;

    int dinnerPresent = 0;
    int dinnerAbsent = 0;
    int dinnerPending = 0;

    for (var s in students) {
      final rawKey = "${now.year}-${now.month}-${now.day}_${s.roomNo}_${s.name}";
      final rec = getAttendanceMerged(rawKey) ?? DailyRecord();
      final l = rec.l.trim();
      final d = rec.d.trim();

      if (l == 'P') {
        lunchPresent++;
      } else if (l == 'A') {
        lunchAbsent++;
      } else {
        lunchPending++;
      }

      if (d == 'P') {
        dinnerPresent++;
      } else if (d == 'A') {
        dinnerAbsent++;
      } else {
        dinnerPending++;
      }
    }

    final int lunchTenderAmount = lunchPresent * globalTenderPrice;
    final int dinnerTenderAmount = dinnerPresent * globalTenderPrice;
    final int totalMealsToday = lunchPresent + dinnerPresent;
    final int totalTenderAmount = lunchTenderAmount + dinnerTenderAmount;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brandDark.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pie_chart_rounded, color: brandDark, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Mess Overview",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: brandDark,
                        ),
                      ),
                      Text(
                        "${now.day}/${now.month}/${now.year} • Live Attendance",
                        style: const TextStyle(fontSize: 11, color: brandGray, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: brandGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "Live",
                        style: TextStyle(
                          color: brandGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Today's Security Pass Color Banner for Admin
            Builder(
              builder: (context) {
                final todayTheme = getTodayPassTheme(now);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        todayTheme.primaryColor.withValues(alpha: 0.12),
                        todayTheme.secondaryColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: todayTheme.primaryColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: todayTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: todayTheme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(todayTheme.emoji, style: const TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "TODAY'S PASS COLOR",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                    color: brandDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: todayTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    todayTheme.dayName.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${todayTheme.dayNameGu} • ${todayTheme.colorName} (${todayTheme.colorNameGu})",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: todayTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                          ),
                        ),
                        onPressed: () => _showWeeklyColorScheduleDialog(),
                        icon: const Icon(Icons.palette_outlined, size: 14, color: brandDark),
                        label: const Text(
                          "All 7 Days",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: brandDark),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Hero Box: Total Meals Served Today
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.restaurant, color: Color(0xFF34D399), size: 15),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "TOTAL MEALS SERVED TODAY",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  "$totalMealsToday",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "Meals (થાળી)",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF34D399),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _showEditTenderPriceDialog(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Tender Total",
                                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 11, color: Colors.amber[300]),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "₹$totalTenderAmount",
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "@ ₹$globalTenderPrice/meal",
                                style: const TextStyle(color: Colors.white60, fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "🥪 Lunch: $lunchPresent (₹$lunchTenderAmount)",
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Container(width: 1, height: 12, color: Colors.white24),
                        Text(
                          "🍛 Dinner: $dinnerPresent (₹$dinnerTenderAmount)",
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Container(width: 1, height: 12, color: Colors.white24),
                        Text(
                          "👥 Total: $totalMealsToday",
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "🥪 Lunch",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: globalEntryL ? brandGreen : brandGray.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                globalEntryL ? "OPEN" : "CLOSED",
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: brandGreen),
                            const SizedBox(width: 4),
                            Text("$lunchPresent Present", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandGreen)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.cancel, size: 14, color: Colors.redAccent),
                            const SizedBox(width: 4),
                            Text("$lunchAbsent Absent", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                          ],
                        ),
                        if (lunchPending > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_filled, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Text("$lunchPending Not Swiped", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: brandGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Lunch Total:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: brandDark)),
                              Text("₹$lunchTenderAmount", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandGreen)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "🍛 Dinner",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: globalEntryD ? brandGreen : brandGray.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                globalEntryD ? "OPEN" : "CLOSED",
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text("$dinnerPresent Present", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.cancel, size: 14, color: Colors.redAccent),
                            const SizedBox(width: 4),
                            Text("$dinnerAbsent Absent", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                          ],
                        ),
                        if (dinnerPending > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_filled, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Text("$dinnerPending Not Swiped", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Dinner Total:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: brandDark)),
                              Text("₹$dinnerTenderAmount", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSwipedSection() {
    DateTime now = realTime;
    final students = globalRegisteredStudents.where((s) => s.isValid).toList();
    final int totalStudents = students.length;

    List<Map<String, dynamic>> lunchSwipedList = [];
    List<Map<String, dynamic>> dinnerSwipedList = [];

    for (var s in students) {
      final rawKey = "${now.year}-${now.month}-${now.day}_${s.roomNo}_${s.name}";
      final rec = getAttendanceMerged(rawKey) ?? DailyRecord();
      if (rec.l.trim() == 'P') {
        lunchSwipedList.add({'student': s, 'time': rec.lTime});
      }
      if (rec.d.trim() == 'P') {
        dinnerSwipedList.add({'student': s, 'time': rec.dTime});
      }
    }

    final currentList = _liveSwipeSelectedMeal == 'l' ? lunchSwipedList : dinnerSwipedList;
    final mealLabel = _liveSwipeSelectedMeal == 'l' ? 'Lunch' : 'Dinner';

    final q = _liveSwipeSearchQuery.trim().toLowerCase();
    final filteredList = currentList.where((item) {
      if (q.isEmpty) return true;
      final RegisteredStudent st = item['student'];
      return st.name.toLowerCase().contains(q) || st.roomNo.toLowerCase().contains(q);
    }).toList();

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brandGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.how_to_reg_rounded, color: brandGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Live Swiped Students",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: brandDark,
                        ),
                      ),
                      Text(
                        "${filteredList.length} of ${currentList.length} shown • $mealLabel Present",
                        style: const TextStyle(fontSize: 11, color: brandGray, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: brandGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: brandGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    "${currentList.length} / $totalStudents",
                    style: const TextStyle(
                      color: brandGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Segmented Meal Selector
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: brandInputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _liveSwipeSelectedMeal = 'l'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _liveSwipeSelectedMeal == 'l' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _liveSwipeSelectedMeal == 'l'
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("🥪 Lunch", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _liveSwipeSelectedMeal == 'l' ? brandGreen : brandGray.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${lunchSwipedList.length}",
                                style: TextStyle(
                                  color: _liveSwipeSelectedMeal == 'l' ? Colors.white : brandDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _liveSwipeSelectedMeal = 'd'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _liveSwipeSelectedMeal == 'd' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _liveSwipeSelectedMeal == 'd'
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("🍛 Dinner", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _liveSwipeSelectedMeal == 'd' ? const Color(0xFF2563EB) : brandGray.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${dinnerSwipedList.length}",
                                style: TextStyle(
                                  color: _liveSwipeSelectedMeal == 'd' ? Colors.white : brandDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
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
            const SizedBox(height: 12),

            TextField(
              controller: _liveSwipeSearchCtrl,
              onChanged: (v) => setState(() => _liveSwipeSearchQuery = v),
              decoration: InputDecoration(
                hintText: "Search swiped student by name or room...",
                hintStyle: const TextStyle(fontSize: 13, color: brandGray),
                prefixIcon: const Icon(Icons.search, size: 18, color: brandGray),
                suffixIcon: _liveSwipeSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: brandGray),
                        onPressed: () {
                          _liveSwipeSearchCtrl.clear();
                          setState(() => _liveSwipeSearchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: brandInputBg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (filteredList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: brandInputBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _liveSwipeSearchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.no_meals_rounded,
                      size: 36,
                      color: brandGray.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _liveSwipeSearchQuery.isNotEmpty
                          ? "No matching student swiped for $mealLabel"
                          : "No students have swiped for $mealLabel yet today.",
                      style: const TextStyle(fontSize: 13, color: brandGray, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 340),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
                  itemBuilder: (ctx, i) {
                    final item = filteredList[i];
                    final RegisteredStudent s = item['student'];
                    final String time = item['time'] ?? '';

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: brandGreen.withValues(alpha: 0.12),
                        backgroundImage: getSafeImageProvider(s.photoUrl),
                        child: (s.photoUrl == null || s.photoUrl!.isEmpty)
                            ? Text(
                                s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: brandGreen, fontWeight: FontWeight.bold, fontSize: 13),
                              )
                            : null,
                      ),
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: brandDark.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Room ${s.roomNo}",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: brandDark),
                            ),
                          ),
                          if (time.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time, size: 12, color: brandGray),
                            const SizedBox(width: 3),
                            Text(
                              time,
                              style: const TextStyle(fontSize: 11, color: brandGray, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: brandGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: brandGreen),
                            SizedBox(width: 4),
                            Text(
                              "Present",
                              style: TextStyle(
                                color: brandGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
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
        ),
      ),
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
                            color: brandGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: checkAdminPermission(widget.phone, 'can_notices')
                        ? IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              await SyncService.deleteNotice(notice.id);
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: checkAdminPermission(widget.phone, 'can_notices')
          ? FloatingActionButton(
              backgroundColor: brandGreen,
              onPressed: _showAddNoticeDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddNoticeDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    final currentAdmin = widget.phone != null
        ? globalAdmins.cast<AdminUser?>().firstWhere(
            (a) => a?.phone == widget.phone,
            orElse: () => null,
          )
        : null;
    final scope = currentAdmin?.hostelScope.trim().toLowerCase() ?? cachedAdminScope?.trim().toLowerCase() ?? 'both';
    String selectedTarget = scope == 'both' ? 'both' : (scope == 'girls' ? 'girls' : 'boys');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "New Notice",
            style: TextStyle(color: brandDark, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scope == 'both') ...[
                  const Text("Send Notice To:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: brandInputBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedTarget,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'both', child: Text("Both Hostels (Boys & Girls)")),
                          DropdownMenuItem(value: 'boys', child: Text("Boys Hostel Only")),
                          DropdownMenuItem(value: 'girls', child: Text("Girls Hostel Only")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedTarget = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: brandGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isNotEmpty && msgCtrl.text.trim().isNotEmpty) {
                  final safeId = "notice_${DateTime.now().millisecondsSinceEpoch}";
                  final newNotice = NoticeItem(
                    safeId,
                    titleCtrl.text.trim(),
                    msgCtrl.text.trim(),
                    realTime,
                  );
                  setState(() {
                    globalNotices.insert(0, newNotice);
                  });
                  await SyncService.pushSingleNotice(newNotice, targetHostel: selectedTarget);
                  NotificationService.sendPushNotificationToStudents(
                    titleCtrl.text.trim(),
                    msgCtrl.text.trim(),
                  );
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
      ),
    );
  }

  void _onLogout() async {
    globalStudentSuffix = null;
    SyncService.cancelAllStreams();
    globalStudentSuffix = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userType');
    await prefs.remove('identifier');
    await prefs.remove('photoPath');
    await prefs.remove('extraInfo');
    await prefs.remove('last_admin_scope');
    cachedAdminScope = null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _toggleMessEntryWithConfirmation(String meal, bool targetValue) async {
    if (SyncService.isSwitchCooldown) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please wait a moment before changing mess entry switch."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final mealName = meal == 'l' ? 'Lunch' : 'Dinner';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (targetValue ? brandGreen : Colors.red).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  targetValue ? Icons.restaurant_rounded : Icons.warning_amber_rounded,
                  color: targetValue ? brandGreen : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  targetValue ? "Open $mealName Mess?" : "Close $mealName Mess?",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: brandDark),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  targetValue
                      ? "Are you sure you want to open $mealName mess entry for students?"
                      : "Are you sure you want to close $mealName mess entry?",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: brandDark),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: targetValue ? Colors.blue.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: targetValue ? Colors.blue.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        targetValue ? Icons.info_outline : Icons.error_outline,
                        size: 18,
                        color: targetValue ? Colors.blue[700] : Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          targetValue
                              ? "A push notification will be sent to all students informing them that $mealName is open."
                              : "⚠️ WARNING: Remaining students who have NOT swiped will be automatically marked as Absent ('A').",
                          style: TextStyle(
                            fontSize: 12,
                            color: targetValue ? Colors.blue[900] : Colors.red[900],
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Cancel / No",
                style: TextStyle(color: brandGray, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: targetValue ? brandGreen : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                targetValue ? "Yes, Open Mess" : "Yes, Close Mess",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      if (mounted) setState(() {});
      return;
    }

    SyncService.setSwitchCooldown(true);
    setState(() {
      if (meal == 'l') {
        globalEntryL = targetValue;
      } else {
        globalEntryD = targetValue;
      }
    });

    if (targetValue == true) {
      final now = realTime;
      final todayStr = "${now.year}-${now.month}-${now.day}";
      if (meal == 'l') globalLunchOpenedDate = todayStr;
      if (meal == 'd') globalDinnerOpenedDate = todayStr;
      NotificationService.sendPushNotificationToStudents(
        "$mealName Time",
        "Mess Open",
      );
    } else {
      await _closeMessAndMarkAbsent(meal);
    }
    await SyncService.pushSwitchesNow();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$mealName mess entry ${targetValue ? 'opened' : 'closed'} successfully."),
          backgroundColor: targetValue ? brandGreen : Colors.red[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _checkAutoClose() async {
    if (!mounted) return;
    if (globalEntryL && isPastLunchCloseTime()) {
      globalEntryL = false;
      await _closeMessAndMarkAbsent('l');
      await SyncService.pushSwitchesNow();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lunch mess entry auto-closed based on scheduled time."),
            backgroundColor: brandDark,
          ),
        );
      }
    }
    if (globalEntryD && isPastDinnerCloseTime()) {
      globalEntryD = false;
      await _closeMessAndMarkAbsent('d');
      await SyncService.pushSwitchesNow();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Dinner mess entry auto-closed based on scheduled time."),
            backgroundColor: brandDark,
          ),
        );
      }
    }
  }

  Future<void> _pickAutoCloseTime(String meal) async {
    final mealName = meal == 'l' ? 'Lunch' : 'Dinner';
    final initialHour = meal == 'l' ? globalLunchCloseHour : globalDinnerCloseHour;
    final initialMinute = meal == 'l' ? globalLunchCloseMinute : globalDinnerCloseMinute;
    
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: "Select $mealName Auto-Close Time",
    );
    
    if (picked != null) {
      setState(() {
        if (meal == 'l') {
          globalLunchCloseHour = picked.hour;
          globalLunchCloseMinute = picked.minute;
        } else {
          globalDinnerCloseHour = picked.hour;
          globalDinnerCloseMinute = picked.minute;
        }
      });
      await SyncService.pushSwitchesNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$mealName auto-close time updated to ${formatTimeOfDay(picked.hour, picked.minute)}."),
            backgroundColor: brandGreen,
          ),
        );
      }
    }
  }

  Future<void> _closeMessAndMarkAbsent(String meal) async {
    try {
      DateTime now = realTime;
      Map<String, dynamic> batchUpdates = {};
      
      if (globalRegisteredStudents.isEmpty) {
        await SyncService.fetchNow();
      }
      
      // Prevent ConcurrentModificationError by creating a copy of the list
      List<RegisteredStudent> studentsCopy = List.from(globalRegisteredStudents);
      
      for (var s in studentsCopy) {
        String rawKey = "${now.year}-${now.month}-${now.day}_${s.roomNo}_${s.name}";
        String safeKey = attendanceSafeKey(rawKey);
        
        if (globalAttendanceMap[safeKey] == null) {
          globalAttendanceMap[safeKey] = DailyRecord();
        }
        
        bool modified = false;
        if (meal == 'l' &&
            (globalAttendanceMap[safeKey]!.l == '' ||
                globalAttendanceMap[safeKey]!.l == '-')) {
          globalAttendanceMap[safeKey]!.l = 'A';
          modified = true;
        } else if (meal == 'd' &&
            (globalAttendanceMap[safeKey]!.d == '' ||
                globalAttendanceMap[safeKey]!.d == '-')) {
          globalAttendanceMap[safeKey]!.d = 'A';
          modified = true;
        }
        
        if (modified) {
          batchUpdates["$safeKey/$meal"] = 'A';
        }
      }
      
      if (batchUpdates.isNotEmpty) {
        await SyncService.pushAttendanceBatch(batchUpdates);
        globalSyncTrigger.value++;
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error in _closeMessAndMarkAbsent: $e");
    }
  }

  void _showSetMenuDialog() async {
    final now = realTime;
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final weekDay = now.weekday;
    final defaultMenu =
        defaultWeeklyMenu[weekDay] ?? defaultWeeklyMenu[DateTime.monday]!;
    String initialBreakfast = defaultMenu['breakfast']!;
    String initialLunch = defaultMenu['lunch']!;
    String initialDinner = defaultMenu['dinner']!;
    try {
      final snap = await FirebaseDatabase.instance
          .ref('hostelData_$globalHostelMode/daily_menus/$todayStr')
          .get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        if (data['breakfast'] != null &&
            data['breakfast'].toString().trim().isNotEmpty)
          initialBreakfast = data['breakfast'];
        if (data['lunch'] != null && data['lunch'].toString().trim().isNotEmpty)
          initialLunch = data['lunch'];
        if (data['dinner'] != null &&
            data['dinner'].toString().trim().isNotEmpty)
          initialDinner = data['dinner'];
      }
    } catch (e) {}
    final bfCtrl = TextEditingController(text: initialBreakfast);
    final luCtrl = TextEditingController(text: initialLunch);
    final dnCtrl = TextEditingController(text: initialDinner);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Edit Today's Menu",
                style: TextStyle(fontWeight: FontWeight.bold, color: brandDark),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: bfCtrl,
                      decoration: const InputDecoration(
                        labelText: "Breakfast",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: luCtrl,
                      decoration: const InputDecoration(
                        labelText: "Lunch",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dnCtrl,
                      decoration: const InputDecoration(
                        labelText: "Dinner",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Photo/PDF Menu (Hidden)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: brandGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (globalMenuUrl == null &&
                        globalMenuFile == null &&
                        globalMenuUploadBytes == null)
                      InkWell(
                        onTap: () async {
                          FilePickerResult? result = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                            withData: true,
                          );
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
                                globalMenuIsPdf =
                                    file.extension?.toLowerCase() == 'pdf';
                              });
                              setState(() {});
                              try {
                                await SyncService.pushMenu();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: brandInputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: brandGreen.withOpacity(0.5),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: brandGreen,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Upload PDF or Image",
                                style: TextStyle(
                                  color: brandGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: brandInputBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              globalMenuIsPdf
                                  ? Icons.picture_as_pdf
                                  : Icons.image,
                              color: brandGreen,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                globalMenuFile != null
                                    ? globalMenuFile!.path
                                          .split('/')
                                          .last
                                          .split('\\')
                                          .last
                                    : 'Uploaded Menu',
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                setDialogState(() {
                                  globalMenuFile = null;
                                  globalMenuUrl = null;
                                  globalMenuUploadBytes = null;
                                  globalMenuIsPdf = false;
                                });
                                setState(() {});
                                try {
                                  await SyncService.pushMenu();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
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
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: brandGray),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await FirebaseDatabase.instance
                        .ref(
                          'hostelData_$globalHostelMode/daily_menus/$todayStr',
                        )
                        .set({
                          'breakfast': bfCtrl.text.trim(),
                          'lunch': luCtrl.text.trim(),
                          'dinner': dnCtrl.text.trim(),
                        });
                    NotificationService.sendPushNotificationToStudents(
                      "Today's Mess Menu is here!",
                      "Breakfast: ${bfCtrl.text.trim()}\nLunch: ${luCtrl.text.trim()}\nDinner: ${dnCtrl.text.trim()}",
                    );
                    globalSyncTrigger.notifyListeners();
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Today's Menu updated!"),
                          backgroundColor: Colors.green,
                        ),
                      );
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

  void _confirmDeletePoll(DynamicPoll poll) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Poll?"),
        content: Text("Are you sure you want to permanently delete '${poll.question}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SyncService.deleteDynamicPoll(poll.id);
              if (mounted) setState(() {});
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPollVotersDialog(DynamicPoll poll, [String? initialOptionFilter]) {
    String selectedOptionFilter = initialOptionFilter ?? 'All';
    String searchQuery = '';
    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            List<Map<String, String>> allVoters = [];
            poll.votes.forEach((key, option) {
              final parts = key.split('_');
              final room = parts.isNotEmpty ? parts[0] : '';
              final name = parts.length > 1 ? parts.sublist(1).join('_') : key;
              allVoters.add({
                'key': key,
                'room': room,
                'name': name,
                'option': option,
              });
            });

            allVoters.sort((a, b) {
              int r = (a['room'] ?? '').compareTo(b['room'] ?? '');
              if (r != 0) return r;
              return (a['name'] ?? '').compareTo(b['name'] ?? '');
            });

            List<Map<String, String>> optionFiltered = selectedOptionFilter == 'All'
                ? allVoters
                : allVoters.where((v) => v['option'] == selectedOptionFilter).toList();

            final q = searchQuery.trim().toLowerCase();
            List<Map<String, String>> filteredVoters = optionFiltered.where((v) {
              if (q.isEmpty) return true;
              return (v['name'] ?? '').toLowerCase().contains(q) ||
                  (v['room'] ?? '').toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: brandGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.how_to_vote_rounded, color: brandGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poll.question,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Total ${allVoters.length} votes cast",
                          style: const TextStyle(fontSize: 12, color: brandGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text("All (${allVoters.length})"),
                            selected: selectedOptionFilter == 'All',
                            onSelected: (sel) {
                              if (sel) setDialogState(() => selectedOptionFilter = 'All');
                            },
                          ),
                          const SizedBox(width: 6),
                          ...poll.options.map((opt) {
                            int count = allVoters.where((v) => v['option'] == opt).length;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text("$opt ($count)"),
                                selected: selectedOptionFilter == opt,
                                onSelected: (sel) {
                                  if (sel) setDialogState(() => selectedOptionFilter = opt);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchCtrl,
                      onChanged: (val) => setDialogState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search by student name or room...",
                        hintStyle: const TextStyle(fontSize: 13, color: brandGray),
                        prefixIcon: const Icon(Icons.search, size: 18, color: brandGray),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setDialogState(() => searchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: brandInputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: filteredVoters.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              child: Text(
                                searchQuery.isNotEmpty
                                    ? "No voters match '$searchQuery'"
                                    : "No voters for this option yet.",
                                style: const TextStyle(color: brandGray),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredVoters.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
                              itemBuilder: (context, i) {
                                final v = filteredVoters[i];
                                final room = v['room'] ?? '';
                                final name = v['name'] ?? '';
                                final opt = v['option'] ?? '';

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: brandGreen.withValues(alpha: 0.12),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: brandGreen, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    "Room $room",
                                    style: const TextStyle(fontSize: 11, color: brandGray, fontWeight: FontWeight.w500),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: brandGreen.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: brandGreen.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      opt,
                                      style: const TextStyle(
                                        color: brandGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _exportPollResultToPdf(poll);
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 16, color: brandDark),
                  label: const Text("Download PDF", style: TextStyle(color: brandDark, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportPollResultToPdf(DynamicPoll poll) async {
    try {
      final pdf = pw.Document();
      final startDt = DateTime.fromMillisecondsSinceEpoch(poll.startTime);
      final endDt = DateTime.fromMillisecondsSinceEpoch(poll.endTime);
      final String dateStr = "${startDt.day}/${startDt.month}/${startDt.year}";
      final String timeStr = "${formatTimeOfDay(startDt.hour, startDt.minute)} - ${formatTimeOfDay(endDt.hour, endDt.minute)}";
      final bool isClosed = !poll.isActive || realTime.millisecondsSinceEpoch > poll.endTime;

      List<List<String>> summaryRows = [];
      int totalVotes = poll.votes.length;
      for (var opt in poll.options) {
        int count = poll.votes.values.where((v) => v == opt).length;
        double pct = totalVotes > 0 ? (count / totalVotes) * 100 : 0.0;
        summaryRows.add([opt, count.toString(), "${pct.toStringAsFixed(1)}%"]);
      }

      List<List<String>> voterRows = [];
      int index = 1;
      var sortedVoteEntries = poll.votes.entries.toList();
      sortedVoteEntries.sort((a, b) {
        final roomA = a.key.split('_').first;
        final roomB = b.key.split('_').first;
        int rComp = roomA.compareTo(roomB);
        if (rComp != 0) return rComp;
        return a.key.compareTo(b.key);
      });

      for (var entry in sortedVoteEntries) {
        final parts = entry.key.split('_');
        final room = parts.isNotEmpty ? parts[0] : '';
        final name = parts.length > 1 ? parts.sublist(1).join('_') : entry.key;
        voterRows.add([
          (index++).toString(),
          room,
          name,
          entry.value,
        ]);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("HOSTEL MESS MANAGEMENT", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  pw.Text(globalHostelMode == 'boys' ? "BOYS HOSTEL" : "GIRLS HOSTEL", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (pw.Context ctx) {
            return [
              pw.Text("Poll Voting Report", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text("Question: ${poll.question}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
              pw.SizedBox(height: 4),
              pw.Text("Date: $dateStr  |  Time: $timeStr  |  Status: ${isClosed ? 'Closed' : 'Active/Live'}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 16),
              pw.Text("Voting Summary", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ["Option", "Votes Count", "Percentage"],
                data: summaryRows,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                cellHeight: 22,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("Total Votes Cast: $totalVotes", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Voter Students List (${voterRows.length} Students)", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if (voterRows.isEmpty)
                pw.Text("No votes cast in this poll yet.", style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600))
              else
                pw.TableHelper.fromTextArray(
                  headers: ["Sr.", "Room No", "Student Name", "Vote Cast"],
                  data: voterRows,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  cellHeight: 20,
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.center,
                  },
                ),
            ];
          },
          footer: (pw.Context ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} by Hostel Mess App", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              pw.Text("Page ${ctx.pageNumber} of ${ctx.pagesCount}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      final String cleanTitle = poll.question.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final String filename = "Poll_${cleanTitle.length > 20 ? cleanTitle.substring(0, 20) : cleanTitle}_${poll.id}.pdf";
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF Export Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditPollDialog(DynamicPoll poll) {
    final qCtrl = TextEditingController(text: poll.question);
    final List<TextEditingController> optCtrls =
        poll.options.map((o) => TextEditingController(text: o)).toList();
    if (optCtrls.isEmpty) {
      optCtrls.add(TextEditingController(text: "Yes"));
      optCtrls.add(TextEditingController(text: "No"));
    }
    DateTime initialStart = DateTime.fromMillisecondsSinceEpoch(poll.startTime);
    DateTime initialEnd = DateTime.fromMillisecondsSinceEpoch(poll.endTime);
    TimeOfDay startTime = TimeOfDay.fromDateTime(initialStart);
    TimeOfDay endTime = TimeOfDay.fromDateTime(initialEnd);
    bool isActive = poll.isActive;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Poll', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: brandDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: qCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Question',
                        filled: true,
                        fillColor: brandInputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Poll Options:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(optCtrls.length, (idx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optCtrls[idx],
                                decoration: InputDecoration(
                                  labelText: "Option ${idx + 1}",
                                  isDense: true,
                                  filled: true,
                                  fillColor: brandInputBg,
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            if (optCtrls.length > 2)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  setDialogState(() {
                                    optCtrls[idx].dispose();
                                    optCtrls.removeAt(idx);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          optCtrls.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 18, color: brandGreen),
                      label: const Text("Add Option", style: TextStyle(color: brandGreen, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Start Time:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: brandDark)),
                        TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (t != null) setDialogState(() => startTime = t);
                          },
                          child: Text(startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: brandGreen)),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("End Time:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: brandDark)),
                        TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (t != null) setDialogState(() => endTime = t);
                          },
                          child: Text(endTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: brandGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Poll Active / Open", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: brandDark)),
                      value: isActive,
                      activeColor: brandGreen,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: brandGray, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (qCtrl.text.trim().isEmpty) return;
                    final validOpts = optCtrls
                        .map((c) => c.text.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();
                    if (validOpts.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter at least 2 options"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final now = realTime;
                    final startDt = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    final endDt = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      endTime.hour,
                      endTime.minute,
                    );
                    if (!endDt.isAfter(startDt)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("End time must be after Start time"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    poll.question = qCtrl.text.trim();
                    poll.options = validOpts;
                    poll.startTime = startDt.millisecondsSinceEpoch;
                    poll.endTime = endDt.millisecondsSinceEpoch;
                    poll.isActive = isActive;

                    Navigator.pop(context);
                    await SyncService.updateDynamicPoll(poll);
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Poll updated successfully!"),
                          backgroundColor: brandGreen,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final List<TextEditingController> optCtrls = [
      TextEditingController(text: "Yes"),
      TextEditingController(text: "No"),
    ];
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(
      hour: math.min(startTime.hour + 2, 23),
      minute: startTime.hour + 2 > 23 ? 59 : startTime.minute,
    );
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Create New Poll', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: brandDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: qCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Question',
                        hintText: "e.g. Today's Lunch Menu Choice?",
                        filled: true,
                        fillColor: brandInputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            label: const Text("Lunch?"),
                            onPressed: () {
                              qCtrl.text = "Today's Lunch?";
                              setDialogState(() {});
                            },
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            label: const Text("Dinner?"),
                            onPressed: () {
                              qCtrl.text = "Today's Dinner?";
                              setDialogState(() {});
                            },
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            label: const Text("Special Menu?"),
                            onPressed: () {
                              qCtrl.text = "Sunday Special Dish?";
                              setDialogState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Poll Options:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              for (var c in optCtrls) {
                                c.dispose();
                              }
                              optCtrls.clear();
                              optCtrls.add(TextEditingController(text: "Yes"));
                              optCtrls.add(TextEditingController(text: "No"));
                            });
                          },
                          child: const Text("Reset Yes/No", style: TextStyle(fontSize: 12, color: brandGray)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...List.generate(optCtrls.length, (idx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optCtrls[idx],
                                decoration: InputDecoration(
                                  labelText: "Option ${idx + 1}",
                                  isDense: true,
                                  filled: true,
                                  fillColor: brandInputBg,
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            if (optCtrls.length > 2)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  setDialogState(() {
                                    optCtrls[idx].dispose();
                                    optCtrls.removeAt(idx);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          optCtrls.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 18, color: brandGreen),
                      label: const Text("Add Option", style: TextStyle(color: brandGreen, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Start Time:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: brandDark)),
                        TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (t != null) setDialogState(() => startTime = t);
                          },
                          child: Text(startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: brandGreen)),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("End Time:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: brandDark)),
                        TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (t != null) setDialogState(() => endTime = t);
                          },
                          child: Text(endTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: brandGreen)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: brandGray, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (qCtrl.text.trim().isEmpty) return;
                    final validOpts = optCtrls
                        .map((c) => c.text.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();
                    if (validOpts.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter at least 2 options"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final now = realTime;
                    final startDt = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    final endDt = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      endTime.hour,
                      endTime.minute,
                    );
                    if (!endDt.isAfter(startDt)) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text("End time must be after Start time"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final poll = DynamicPoll(
                      id: realTime.millisecondsSinceEpoch.toString(),
                      question: qCtrl.text.trim(),
                      options: validOpts,
                      startTime: startDt.millisecondsSinceEpoch,
                      endTime: endDt.millisecondsSinceEpoch,
                      isActive: true,
                      votes: {},
                    );
                    Navigator.pop(context);
                    await SyncService.createDynamicPoll(poll);
                    NotificationService.sendPushNotificationToStudents(
                      "New Poll: ${poll.question}",
                      "Open the app to cast your vote.",
                    );
                    if (mounted) setState(() {});
                  },
                  child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final activeScope = getAdminHostelScope(widget.phone);
    if (activeScope == 'boys' && globalHostelMode != 'boys') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && globalHostelMode != 'boys') {
          SyncService.switchMode('boys');
        }
      });
    } else if (activeScope == 'girls' && globalHostelMode != 'girls') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && globalHostelMode != 'girls') {
          SyncService.switchMode('girls');
        }
      });
    }
    return Stack(
      children: [
        Scaffold(
          backgroundColor: brandBg,
          appBar: AppBar(
            backgroundColor: brandGreen,
            title: Builder(
              builder: (context) {
                final roleName = getAdminRoleDisplayName(widget.phone);
                final scope = getAdminHostelScope(widget.phone);
                if (scope == 'boys') {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$roleName  ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Boys",
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (scope == 'girls') {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$roleName  ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Girls",
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$roleName  ",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (globalHostelMode != 'boys') {
                                await SyncService.switchMode('boys');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: globalHostelMode == 'boys'
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "Boys",
                                style: TextStyle(
                                  color: globalHostelMode == 'boys'
                                      ? const Color(0xFF2E7D32)
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (globalHostelMode != 'girls') {
                                await SyncService.switchMode('girls');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: globalHostelMode == 'girls'
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "Girls",
                                style: TextStyle(
                                  color: globalHostelMode == 'girls'
                                      ? const Color(0xFF2E7D32)
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text("Refreshing all data..."),
                        ],
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  DateTime now = realTime;
                  String monthKey = "${globalHostelMode}_${now.year}-${now.month}";
                  _fetchedApiMonths.remove(monthKey);
                  await fetchAttendanceMonth(now.year, now.month);
                  await SyncService.fetchNow();
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("App refreshed successfully! 🔄"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
            leading: Builder(
              builder: (context) {
                final canComplaints = checkAdminPermission(widget.phone, 'can_complaints');
                int unread = canComplaints
                    ? globalComplaints
                        .where(
                          (c) =>
                              c.date.isAfter(globalAdminLastViewedComplaints) &&
                              !globalAdminHiddenComplaints.contains(c.id),
                        )
                        .length
                    : 0;
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
                  decoration: const BoxDecoration(color: brandGreen),
                  accountName: Text(
                    widget.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_outlined, color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            "Logged in as: ${getAdminRoleDisplayName(widget.phone)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    child:
                        (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                        ? ClipOval(
                            child: Image.network(
                              widget.photoUrl!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: Colors.white),
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.white),
                  ),
                ),
                if (checkAdminPermission(widget.phone, 'can_manage_meals'))
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
                        activeColor: brandGreen,
                        value: globalEntryL,
                        onChanged: (v) => _toggleMessEntryWithConfirmation('l', v),
                      ),
                      SwitchListTile(
                        title: const Text('Dinner'),
                        activeColor: brandGreen,
                        value: globalEntryD,
                        onChanged: (v) => _toggleMessEntryWithConfirmation('d', v),
                      ),
                    ],
                  ),
                if (checkAdminPermission(widget.phone, 'can_manage_polls'))
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
                if (checkAdminPermission(widget.phone, 'can_attendance'))
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
                          builder: (_) => AdminAttendanceScreen(adminPhone: widget.phone),
                        ),
                      );
                    },
                  ),
                if (checkAdminPermission(widget.phone, 'can_students_manage'))
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
                          builder: (context) =>
                              const AdminRegisteredStudentsScreen(),
                        ),
                      );
                    },
                  ),
                if (checkAdminPermission(widget.phone, 'can_set_menu'))
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
                if (checkAdminPermission(widget.phone, 'can_edit_timetable'))
                  ListTile(
                    leading: const Icon(Icons.edit_calendar, color: brandDark),
                    title: const Text(
                      'Edit Weekly Timetable',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => const WeeklyMenuEditorWidget(),
                      );
                    },
                  ),
                if (checkAdminPermission(widget.phone, 'can_complaints'))
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
                            Text(
                              'View Complaints (${globalHostelMode == 'boys' ? 'Boys' : 'Girls'})',
                              style: const TextStyle(fontWeight: FontWeight.w500),
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
                            globalAdminLastViewedComplaints = realTime;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminComplaintsScreen(
                                hidden: globalAdminHiddenComplaints,
                                adminPhone: widget.phone,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutDevelopersScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                if (checkAdminPermission(widget.phone, 'can_students_manage'))
                  ListTile(
                    leading: const Icon(Icons.people_alt, color: brandDark),
                    title: const Text(
                      'Manage Students',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageStudentsScreen(),
                        ),
                      );
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
                      child:
                          (widget.photoUrl != null &&
                              widget.photoUrl!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                widget.photoUrl!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getAdminRoleDisplayName(widget.phone),
                            style: const TextStyle(
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
                            maxLines: 3,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ), // Main Body Content
              Expanded(
                child: _selectedIndex == 0
                    ? _buildAdminHomeTab()
                    : _selectedIndex == 1
                    ? _buildNoticeTab()
                    : const ViewMenuTab(),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex >= 3 ? 0 : _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            selectedItemColor: brandGreen,
            unselectedItemColor: brandGray,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: "Notice",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: "Menu",
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
  @override
  void initState() {
    super.initState();
    SyncService.fetchNow();
  }

  void _tryOpenAddComplaint() {
    final isPortalOpen = globalComplaintWindowConfig.isCurrentlyOpen();
    if (!isPortalOpen) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.lock, color: Colors.orange),
              SizedBox(width: 8),
              Text("Portal Closed", style: TextStyle(color: brandDark, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            (globalComplaintWindowConfig.noticeMessage != null && globalComplaintWindowConfig.noticeMessage!.isNotEmpty)
                ? globalComplaintWindowConfig.noticeMessage!
                : (globalComplaintWindowConfig.mode == 'dates' && globalComplaintWindowConfig.startDate != null
                    ? "Complaints are only accepted between ${globalComplaintWindowConfig.startDate} and ${globalComplaintWindowConfig.endDate}."
                    : "Complaints portal is currently closed by the Admin. Please wait for the next scheduled date."),
            style: const TextStyle(color: brandDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: brandGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final now = realTime;
    final currentMonthCount = globalComplaints.where((c) =>
      c.studentName == widget.name &&
      c.date.year == now.year &&
      c.date.month == now.month
    ).length;

    final maxLimit = globalComplaintWindowConfig.maxPerMonth;
    if (currentMonthCount >= maxLimit) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text("Monthly Limit Reached", style: TextStyle(color: brandDark, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "You have reached your limit of $maxLimit complaints for this month (${now.month}/${now.year}).\n\nYou will be able to submit new complaints on the 1st of next month.",
            style: const TextStyle(color: brandDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: brandGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    _showAddDialog();
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String? localComplaintImageUrl;
    bool isUploading = false;
    final ImagePicker _picker = ImagePicker();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.rate_review, color: brandGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "New Complaint (${globalHostelMode == 'boys' ? 'Boys' : 'Girls'})",
                    style: const TextStyle(color: brandDark, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
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
                        onPressed: isUploading
                            ? null
                            : () async {
                                final XFile? image = await _picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 35,
                                  maxWidth: 600,
                                  maxHeight: 600,
                                );
                                if (image != null) {
                                  setStateSB(() {
                                    isUploading = true;
                                  });
                                  final bytes = await image.readAsBytes();
                                  final base64Str =
                                      "data:image/jpeg;base64,${base64Encode(bytes)}";
                                  setStateSB(() {
                                    isUploading = false;
                                    localComplaintImageUrl = base64Str;
                                  });
                                }
                              },
                        icon: const Icon(Icons.photo),
                        label: Text(
                          isUploading ? "Uploading..." : "Attach Photo",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandInputBg,
                          foregroundColor: brandDark,
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (localComplaintImageUrl != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                    final now = realTime;
                    final currentMonthCount = globalComplaints.where((c) =>
                      c.studentName == widget.name &&
                      c.date.year == now.year &&
                      c.date.month == now.month
                    ).length;
                    if (currentMonthCount >= globalComplaintWindowConfig.maxPerMonth) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Monthly limit of ${globalComplaintWindowConfig.maxPerMonth} complaints reached."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final safeId = "complaint_${DateTime.now().millisecondsSinceEpoch}_${widget.roomNo}_${widget.name}".replaceAll(RegExp(r'[.#$\[\]/\s]'), '_');
                    final newComplaint = ComplaintItem(
                      safeId,
                      titleCtrl.text.trim(),
                      msgCtrl.text.trim(),
                      realTime,
                      widget.name,
                      widget.roomNo,
                      widget.photoUrl,
                      localComplaintImageUrl,
                    );
                    setState(() {
                      globalComplaints.insert(0, newComplaint);
                    });
                    await SyncService.pushSingleComplaint(newComplaint);
                    NotificationService.sendPushNotificationToAdmins(
                      "New Complaint (${globalHostelMode.toUpperCase()}): ${titleCtrl.text}",
                      "${widget.name} (${widget.roomNo}) has submitted a complaint.",
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  "Submit",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mess Complaints", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              globalHostelMode == 'boys' ? "👦 Boys Hostel Mess" : "👧 Girls Hostel Mess",
              style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: brandGreen,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: globalSyncTrigger,
        builder: (context, _, __) {
          final isPortalOpen = globalComplaintWindowConfig.isCurrentlyOpen();
          final now = realTime;
          final currentMonthCount = globalComplaints.where((c) =>
            c.studentName == widget.name &&
            c.date.year == now.year &&
            c.date.month == now.month
          ).length;
          final maxLimit = globalComplaintWindowConfig.maxPerMonth;
          final isLimitReached = currentMonthCount >= maxLimit;

          final myComplaints = globalComplaints
              .where(
                (c) =>
                    c.studentName == widget.name &&
                    !globalStudentHiddenComplaints.contains(c.id),
              )
              .toList();
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: !isPortalOpen
                      ? const Color(0xFFFFF3E0)
                      : (isLimitReached ? const Color(0xFFFFEBEE) : const Color(0xFFFFF7ED)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: !isPortalOpen
                        ? Colors.orange.shade300
                        : (isLimitReached ? Colors.red.shade300 : Colors.green.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      !isPortalOpen
                          ? Icons.lock
                          : (isLimitReached ? Icons.error_outline : Icons.check_circle_outline),
                      color: !isPortalOpen
                          ? Colors.orange.shade800
                          : (isLimitReached ? Colors.red.shade700 : Colors.green.shade700),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !isPortalOpen
                                ? "Complaint Portal Closed"
                                : (isLimitReached
                                    ? "Monthly Limit Reached ($currentMonthCount/$maxLimit)"
                                    : "Complaints This Month: $currentMonthCount / $maxLimit"),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: !isPortalOpen
                                  ? Colors.orange.shade900
                                  : (isLimitReached ? Colors.red.shade900 : Colors.green.shade900),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            !isPortalOpen
                                ? ((globalComplaintWindowConfig.noticeMessage != null && globalComplaintWindowConfig.noticeMessage!.isNotEmpty)
                                    ? globalComplaintWindowConfig.noticeMessage!
                                    : (globalComplaintWindowConfig.mode == 'dates' && globalComplaintWindowConfig.startDate != null
                                        ? "Allowed: ${globalComplaintWindowConfig.startDate} to ${globalComplaintWindowConfig.endDate}"
                                        : "Complaints are currently closed by admin."))
                                : (isLimitReached
                                    ? "Limit resets on 1st of next month."
                                    : "${maxLimit - currentMonthCount} complaints remaining for this month."),
                            style: TextStyle(
                              fontSize: 11,
                              color: !isPortalOpen
                                  ? Colors.orange.shade800
                                  : (isLimitReached ? Colors.red.shade800 : Colors.green.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: myComplaints.isEmpty
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
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: brandDark,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: globalHostelMode == 'boys'
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFFDF2F8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: globalHostelMode == 'boys'
                                            ? const Color(0xFF93C5FD)
                                            : const Color(0xFFF472B6),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          globalHostelMode == 'boys' ? Icons.male : Icons.female,
                                          size: 13,
                                          color: globalHostelMode == 'boys' ? const Color(0xFF1D4ED8) : const Color(0xFFBE185D),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          globalHostelMode == 'boys' ? "Boys Mess" : "Girls Mess",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: globalHostelMode == 'boys' ? const Color(0xFF1D4ED8) : const Color(0xFFBE185D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    c.description,
                                    style: const TextStyle(color: brandGray),
                                  ),
                                  if (c.complaintImageUrl != null &&
                                      c.complaintImageUrl!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    buildComplaintImageWidget(c.complaintImageUrl!),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    formatDateTime(c.date),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: brandGreen,
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
                                  setState(
                                    () => globalStudentHiddenComplaints.add(c.id),
                                  );
                                  saveStudentHiddenComplaints();
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: globalSyncTrigger,
        builder: (context, _, __) {
          final isPortalOpen = globalComplaintWindowConfig.isCurrentlyOpen();
          final now = realTime;
          final currentMonthCount = globalComplaints.where((c) =>
            c.studentName == widget.name &&
            c.date.year == now.year &&
            c.date.month == now.month
          ).length;
          final isLimitReached = currentMonthCount >= globalComplaintWindowConfig.maxPerMonth;
          return FloatingActionButton(
            onPressed: _tryOpenAddComplaint,
            backgroundColor: (!isPortalOpen || isLimitReached) ? Colors.grey : brandGreen,
            child: Icon((!isPortalOpen) ? Icons.lock : Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }
}

class AdminComplaintsScreen extends StatefulWidget {
  final Set<String> hidden;
  final Function(String) onDelete;
  final String? adminPhone;
  const AdminComplaintsScreen({
    super.key,
    required this.hidden,
    required this.onDelete,
    this.adminPhone,
  });
  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    SyncService.fetchNow();
  }

  void _showScheduleDialog() {
    bool currentIsOpen = globalComplaintWindowConfig.isOpen;
    String currentMode = globalComplaintWindowConfig.mode; // 'toggle' or 'dates'
    String? currentStartDate = globalComplaintWindowConfig.startDate;
    String? currentEndDate = globalComplaintWindowConfig.endDate;
    int currentMax = globalComplaintWindowConfig.maxPerMonth;
    final noticeCtrl = TextEditingController(text: globalComplaintWindowConfig.noticeMessage ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.tune, color: brandGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Complaint Window (${globalHostelMode.toUpperCase()})",
                    style: const TextStyle(color: brandDark, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Control Mode:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                  RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Manual ON/OFF Switch", style: TextStyle(fontSize: 13)),
                    value: 'toggle',
                    groupValue: currentMode,
                    activeColor: brandGreen,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => currentMode = val);
                    },
                  ),
                  RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Scheduled Date Range", style: TextStyle(fontSize: 13)),
                    value: 'dates',
                    groupValue: currentMode,
                    activeColor: brandGreen,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => currentMode = val);
                    },
                  ),
                  const Divider(),
                  if (currentMode == 'toggle') ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Accept Complaints", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                        currentIsOpen ? "Students can submit complaints" : "Portal is closed for students",
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: currentIsOpen,
                      activeColor: brandGreen,
                      onChanged: (val) {
                        setDialogState(() => currentIsOpen = val);
                      },
                    ),
                  ] else ...[
                    const Text("Active Dates:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: currentStartDate != null ? (DateTime.tryParse(currentStartDate!) ?? DateTime.now()) : DateTime.now(),
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  currentStartDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              currentStartDate != null ? "From: $currentStartDate" : "Pick Start Date",
                              style: const TextStyle(fontSize: 11, color: brandDark),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: currentEndDate != null ? (DateTime.tryParse(currentEndDate!) ?? DateTime.now()) : DateTime.now(),
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  currentEndDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              currentEndDate != null ? "To: $currentEndDate" : "Pick End Date",
                              style: const TextStyle(fontSize: 11, color: brandDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text("Monthly Limit per Student:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: currentMax,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: brandInputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: [1, 2, 3, 4, 5, 10].map((v) => DropdownMenuItem(
                      value: v,
                      child: Text("$v complaints / month"),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => currentMax = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text("Notice Message for Students (Optional):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noticeCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "e.g. Complaints window is open from 15th to 17th Oct.",
                      hintStyle: const TextStyle(fontSize: 12),
                      filled: true,
                      fillColor: brandInputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("Cancel", style: TextStyle(color: brandGray)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final newCfg = ComplaintWindowConfig(
                    isOpen: currentIsOpen,
                    mode: currentMode,
                    startDate: currentStartDate,
                    endDate: currentEndDate,
                    maxPerMonth: currentMax,
                    noticeMessage: noticeCtrl.text.trim().isEmpty ? null : noticeCtrl.text.trim(),
                  );
                  await SyncService.saveComplaintWindowConfig(newCfg);
                  Navigator.pop(dialogCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Complaint settings updated for ${globalHostelMode.toUpperCase()}!"),
                        backgroundColor: brandGreen,
                      ),
                    );
                  }
                },
                child: const Text("Save Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = widget.adminPhone == null ||
        checkAdminPermission(widget.adminPhone!, 'can_manage_complaint_window');
    final currentAdmin = widget.adminPhone != null
        ? globalAdmins.cast<AdminUser?>().firstWhere(
            (a) => a?.phone == widget.adminPhone,
            orElse: () => null,
          )
        : null;
    final scope = currentAdmin?.hostelScope.trim().toLowerCase() ?? cachedAdminScope?.trim().toLowerCase() ?? 'both';
    final bool canSwitchHostel = (scope == 'both');

    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Student Complaints", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              globalHostelMode == 'boys' ? "👦 Boys Hostel Mess" : "👧 Girls Hostel Mess",
              style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: brandGreen,
        foregroundColor: Colors.white,
        actions: [
          if (canSwitchHostel)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (globalHostelMode != 'boys') {
                        await SyncService.switchMode('boys');
                        if (mounted) setState(() {});
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: globalHostelMode == 'boys' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "Boys",
                        style: TextStyle(
                          color: globalHostelMode == 'boys' ? brandGreen : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (globalHostelMode != 'girls') {
                        await SyncService.switchMode('girls');
                        if (mounted) setState(() {});
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: globalHostelMode == 'girls' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "Girls",
                        style: TextStyle(
                          color: globalHostelMode == 'girls' ? brandGreen : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (canManage)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: "Complaint Window & Schedule",
              onPressed: _showScheduleDialog,
            ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: globalSyncTrigger,
        builder: (context, _, __) {
          final isPortalOpen = globalComplaintWindowConfig.isCurrentlyOpen();
          final visible = globalComplaints
              .where((c) => !widget.hidden.contains(c.id))
              .toList();

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isPortalOpen ? const Color(0xFFFFF7ED) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isPortalOpen ? Colors.green.shade300 : Colors.orange.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPortalOpen ? Icons.check_circle : Icons.lock,
                      size: 20,
                      color: isPortalOpen ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Portal: ${isPortalOpen ? 'OPEN' : 'CLOSED'} (${globalHostelMode.toUpperCase()})",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isPortalOpen ? Colors.green.shade900 : Colors.orange.shade900,
                            ),
                          ),
                          Text(
                            globalComplaintWindowConfig.mode == 'dates' && globalComplaintWindowConfig.startDate != null
                                ? "Dates: ${globalComplaintWindowConfig.startDate} to ${globalComplaintWindowConfig.endDate} (Max: ${globalComplaintWindowConfig.maxPerMonth}/mo)"
                                : "Mode: Manual Switch (Max: ${globalComplaintWindowConfig.maxPerMonth}/student/mo)",
                            style: TextStyle(
                              fontSize: 11,
                              color: isPortalOpen ? Colors.green.shade800 : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canManage)
                      TextButton(
                        onPressed: _showScheduleDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
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
                                child: (c.studentPhotoUrl != null &&
                                        c.studentPhotoUrl!.isNotEmpty)
                                    ? ClipOval(
                                        child: Image.network(
                                          c.studentPhotoUrl!,
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.person, color: Colors.white),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: brandDark,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: globalHostelMode == 'boys'
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFFDF2F8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: globalHostelMode == 'boys'
                                            ? const Color(0xFF93C5FD)
                                            : const Color(0xFFF472B6),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          globalHostelMode == 'boys' ? Icons.male : Icons.female,
                                          size: 13,
                                          color: globalHostelMode == 'boys' ? const Color(0xFF1D4ED8) : const Color(0xFFBE185D),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          globalHostelMode == 'boys' ? "Boys Mess" : "Girls Mess",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: globalHostelMode == 'boys' ? const Color(0xFF1D4ED8) : const Color(0xFFBE185D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    c.description,
                                    style: const TextStyle(color: brandDark),
                                  ),
                                  if (c.complaintImageUrl != null &&
                                      c.complaintImageUrl!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    buildComplaintImageWidget(c.complaintImageUrl!),
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
                                      color: brandGreen,
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
                      ),
              ),
            ],
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
        backgroundColor: brandGreen,
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
                      backgroundColor: brandGreen,
                      child: (s.photoUrl != null && s.photoUrl!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                s.photoUrl!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
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
            border: Border.all(color: brandGreen.withOpacity(0.5)),
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
                      color: brandGreen,
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

class _MealPassScreenState extends State<MealPassScreen> with SingleTickerProviderStateMixin {
  late Timer _timer;
  DateTime _now = realTime;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = realTime;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt, DayPassTheme theme) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return "${theme.dayName.toUpperCase()}, ${pad(dt.day)} ${_getMonthName(dt.month).toUpperCase()} ${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = getTodayPassTheme(_now);
    String pad(int n) => n.toString().padLeft(2, '0');
    final String period = _now.hour >= 12 ? 'PM' : 'AM';
    int hour12 = _now.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final String timeStr = "${pad(hour12)}:${pad(_now.minute)}:${pad(_now.second)} $period";

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor,
              theme.secondaryColor,
              theme.badgeBgColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Live pulsing indicator
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.greenAccent.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.greenAccent,
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "LIVE TICKING PASS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 40), // Balance close button
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Day & Meal Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  theme.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${theme.dayName.toUpperCase()} PASS (${theme.dayNameGu})",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Approved Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, color: Colors.greenAccent, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  "${widget.mealName.toUpperCase()} APPROVED",
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Extra Large Photo
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 25,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: theme.accentColor.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 4.5),
                            ),
                            child: CircleAvatar(
                              radius: 75,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        widget.photoUrl!,
                                        fit: BoxFit.cover,
                                        width: 150,
                                        height: 150,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.person, color: Colors.white, size: 85),
                                      ),
                                    )
                                  : const Icon(Icons.person, color: Colors.white, size: 85),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Extra Large Student Name
                          Text(
                            widget.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Extra Large Room Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.meeting_room_rounded, color: theme.primaryColor, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  "ROOM: ${widget.roomNo}",
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Large Date Display Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month_rounded, color: theme.accentColor, size: 22),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    _formatDate(_now, theme),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Extra Large Live Digital Clock Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: theme.accentColor.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.access_time_filled, color: Colors.amberAccent, size: 28),
                                    const SizedBox(width: 10),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.5,
                                        fontFamily: 'monospace',
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "LIVE TIME • RUNNING SECONDS",
                                  style: TextStyle(
                                    color: theme.accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Anti-Screenshot & Security Notice
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.security, color: Colors.white70, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  "PASS ID: #${widget.roomNo}-${pad(_now.minute)}${pad(_now.second)} • NO SCREENSHOTS",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Done / Back Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: theme.primaryColor,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.check_circle, size: 22),
                              label: const Text(
                                "Done / પાછા જાઓ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminAttendanceScreen extends StatefulWidget {
  final String? adminPhone;
  const AdminAttendanceScreen({super.key, this.adminPhone});
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
  } // --- TEMPORARY EDITING BLOCK START ---

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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: brandDark,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onExcel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.table_chart, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "Excel",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onPdf,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "PDF",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
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
        int payable = (p == 0 && a == 0)
            ? 0
            : calculatePayableBill(actual ~/ 70);
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
                  Icon(Icons.lock_outline, color: brandGreen),
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter security password to enable editing mode:",
                      style: TextStyle(fontSize: 13, color: brandGray),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passCtrl,
                      obscureText: isObscured,
                      keyboardType: TextInputType.text,
                      maxLength: 35,
                      decoration: InputDecoration(
                        labelText: "Security Password",
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
                    backgroundColor: brandGreen,
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

  Future<void> _showAttendanceChoiceDialog({
    required BuildContext context,
    required String studentName,
    required String roomNo,
    required String dateLabel,
    required String mealType,
    required String rawKey,
    required VoidCallback onUpdated,
  }) async {
    String key = attendanceSafeKey(rawKey);
    DailyRecord rec = getAttendanceMerged(key) ?? getAttendanceMerged(rawKey) ?? DailyRecord();
    String currentStatus = mealType == 'L' ? rec.l.trim() : rec.d.trim();
    if (currentStatus.isEmpty) currentStatus = '-';

    String mealName = mealType == 'L' ? 'Lunch' : 'Dinner';

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (mealType == 'L' ? brandGreen : const Color(0xFF2563EB)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        mealType == 'L' ? Icons.lunch_dining : Icons.dinner_dining,
                        color: mealType == 'L' ? brandGreen : const Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: brandDark,
                            ),
                          ),
                          Text(
                            "Room $roomNo • $dateLabel • $mealName",
                            style: const TextStyle(fontSize: 12, color: brandGray),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentStatus == 'P'
                            ? Colors.green.withValues(alpha: 0.1)
                            : (currentStatus == 'A' ? Colors.redAccent.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Current: $currentStatus",
                        style: TextStyle(
                          color: currentStatus == 'P'
                              ? Colors.green
                              : (currentStatus == 'A' ? Colors.redAccent : brandGray),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.check, color: Colors.green),
                  ),
                  title: const Text(
                    "Mark as Present (P)",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  subtitle: const Text("Student attended this meal"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (mealType == 'L') {
                      rec.l = 'P';
                      rec.lTime = formatTimeOfDay(realTime.hour, realTime.minute);
                    } else {
                      rec.d = 'P';
                      rec.dTime = formatTimeOfDay(realTime.hour, realTime.minute);
                    }
                    globalAttendanceMap[key] = rec;
                    await SyncService.pushAttendance(key, rec);
                    onUpdated();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(Icons.close, color: Colors.redAccent),
                  ),
                  title: const Text(
                    "Mark as Absent (A)",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  subtitle: const Text("Student did not attend this meal"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (mealType == 'L') {
                      rec.l = 'A';
                      rec.lTime = '';
                    } else {
                      rec.d = 'A';
                      rec.dTime = '';
                    }
                    globalAttendanceMap[key] = rec;
                    await SyncService.pushAttendance(key, rec);
                    onUpdated();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3F4F6),
                    child: Icon(Icons.remove, color: brandGray),
                  ),
                  title: const Text(
                    "Clear / Unmark (-)",
                    style: TextStyle(fontWeight: FontWeight.w600, color: brandDark),
                  ),
                  subtitle: const Text("Reset to empty slot"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (mealType == 'L') {
                      rec.l = '';
                      rec.lTime = '';
                    } else {
                      rec.d = '';
                      rec.dTime = '';
                    }
                    globalAttendanceMap[key] = rec;
                    await SyncService.pushAttendance(key, rec);
                    onUpdated();
                  },
                ),
              ],
            ),
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Factory Reset Data",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "WARNING: This will wipe all students, attendance, complaints, and notices! Enter the master password to proceed:",
                      style: TextStyle(fontSize: 13, color: brandGray),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passCtrl,
                      obscureText: isObscured,
                      decoration: InputDecoration(
                        labelText: "Master Password",
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
                          onPressed: () =>
                              setDialogState(() => isObscured = !isObscured),
                        ),
                      ),
                    ),
                  ],
                ),
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
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (hashPassword(passCtrl.text) ==
                        "f0ff3b50086e347379ef2f8dbc1227a6949e6cd03123c03ef3f3f7adc8da96be") {
                      Navigator.pop(ctx);
                      await _performReset();
                    } else {
                      setDialogState(() => errorText = "Incorrect password!");
                    }
                  },
                  child: const Text(
                    "WIPE DATA",
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

  Future<void> _performReset() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final dbRef = FirebaseDatabase.instance.ref(
        'hostelData_$globalHostelMode',
      );
      await dbRef.child('students').remove();
      await dbRef.child('attendance').remove();
      await dbRef.child('paid').remove();
      await dbRef.child('polls').remove();
      await dbRef.child('notices').remove();
      await dbRef.child('complaints').remove();
      globalRegisteredStudents.clear();
      globalAttendanceMap.clear();
      globalMonthlyPaid.clear();
      globalEntryL = false;
      globalEntryD = false;
      globalNotices.clear();
      globalComplaints.clear();
      SyncService.dynamicPolls.clear();
      await SyncService.pushStudents();
      await dbRef
          .child('force_logout')
          .set(realTime.millisecondsSinceEpoch);
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
      await prefs.remove('last_admin_scope');
      cachedAdminScope = null;
      Navigator.pop(context); // close loading
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All data has been reset!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  } // --- TEMPORARY EDITING BLOCK END ---

  DateTime _selectedDailyDate = realTime;
  String _dailySearchQuery = "";
  DateTime _selectedMonth = DateTime(realTime.year, realTime.month);
  String _monthlySearchQuery = "";
  String _paymentFilter = "All"; // All, Paid, Unpaid, Half Paid
  int _getDaysInMonth(int y, int m) =>
      DateTime(y, m + 1, 0).day; // ===== DAILY VIEW LOGIC =====
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
          if (rec.l == 'P') total += globalTenderPrice;
          if (rec.d == 'P') total += globalTenderPrice;
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
    int dailyLunchCount = rows.where((r) => r['l'] == 'P').length;
    int dailyDinnerCount = rows.where((r) => r['d'] == 'P').length;
    int dailyLunchTotal = dailyLunchCount * globalTenderPrice;
    int dailyDinnerTotal = dailyDinnerCount * globalTenderPrice;
    int dailyGrandTotal = dailyLunchTotal + dailyDinnerTotal;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "🥪 Lunch: $dailyLunchCount (₹$dailyLunchTotal)",
                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Container(width: 1, height: 14, color: Colors.white24),
              Text(
                "🍛 Dinner: $dailyDinnerCount (₹$dailyDinnerTotal)",
                style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Container(width: 1, height: 14, color: Colors.white24),
              Text(
                "💰 Total: ₹$dailyGrandTotal",
                style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 11),
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
                ); // --- TEMPORARY EDITING BLOCK START ---
                if (isEditingEnabled && !isEmpty) {
                  return InkWell(
                    onTap: () {
                      String rawKey =
                          "${_selectedDailyDate.year}-${_selectedDailyDate.month}-${_selectedDailyDate.day}_${room}_${name}";
                      String dateLabel =
                          "${_selectedDailyDate.day}/${_selectedDailyDate.month}/${_selectedDailyDate.year}";
                      _showAttendanceChoiceDialog(
                        context: context,
                        studentName: name,
                        roomNo: room,
                        dateLabel: dateLabel,
                        mealType: mealType,
                        rawKey: rawKey,
                        onUpdated: () => setState(() {}),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.blue.withOpacity(0.1),
                      child: textWidget,
                    ),
                  );
                } // --- TEMPORARY EDITING BLOCK END ---
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
                        maxLines: 3,
                        overflow: TextOverflow.visible,
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
                          color: row['total'] > 0 ? brandGreen : brandGray,
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
  } // ===== MONTHLY VIEW LOGIC =====

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
    } // Sort by Room No
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
            } // --- TEMPORARY EDITING BLOCK END ---
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
                                maxLines: 3,
                                overflow: TextOverflow.visible,
                              ), // --- TEMPORARY EDITING BLOCK START ---
                              Text(
                                "Month: ${_selectedMonth.month}/${_selectedMonth.year} | Payable: ₹$currentPayable",
                                style: const TextStyle(
                                  color: brandGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ), // --- TEMPORARY EDITING BLOCK END ---
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
                                ); // --- TEMPORARY EDITING BLOCK START ---
                                if (isEditingEnabled) {
                                  return InkWell(
                                    onTap: () {
                                      String rawKey =
                                          "${_selectedMonth.year}-${_selectedMonth.month}-${h['day']}_${student.roomNo}_${student.name}";
                                      String dateLabel =
                                          "${h['day']}/${_selectedMonth.month}/${_selectedMonth.year}";
                                      _showAttendanceChoiceDialog(
                                        context: context,
                                        studentName: student.name,
                                        roomNo: student.roomNo,
                                        dateLabel: dateLabel,
                                        mealType: mealType,
                                        rawKey: rawKey,
                                        onUpdated: () {
                                          setModalState(() {});
                                          setState(() {});
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      color: Colors.blue.withOpacity(0.1),
                                      child: textWidget,
                                    ),
                                  );
                                } // --- TEMPORARY EDITING BLOCK END ---
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
                                String key =
                                    "${_selectedMonth.year}-${m}_${student.roomNo}_${student.name}";
                                int paid = globalMonthlyPaid[key] ?? 0;
                                int p = 0;
                                int a = 0;
                                for (int day = 1; day <= 31; day++) {
                                  String dKey =
                                      "${_selectedMonth.year}-${m}-${day}_${student.roomNo}_${student.name}";
                                  DailyRecord? rec = getAttendanceMerged(dKey);
                                  if (rec != null) {
                                    if (rec.l == "P")
                                      p++;
                                    else if (rec.l == "A")
                                      a++;
                                    if (rec.d == "P")
                                      p++;
                                    else if (rec.d == "A")
                                      a++;
                                  }
                                }
                                int actual = p * 70;
                                int payable = (p == 0 && a == 0)
                                    ? 0
                                    : calculatePayableBill(p);
                                int due = payable - paid;
                                if (p > 0 || a > 0 || paid > 0) {
                                  d.add([
                                    m.toString(),
                                    p.toString(),
                                    a.toString(),
                                    actual.toString(),
                                    payable.toString(),
                                    paid.toString(),
                                    due.toString(),
                                  ]);
                                }
                              }
                              ExportService.exportReport(
                                context: context,
                                title:
                                    "${student.name} - Yearly ${_selectedMonth.year}",
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
                                String key =
                                    "${_selectedMonth.year}-${m}_${student.roomNo}_${student.name}";
                                int paid = globalMonthlyPaid[key] ?? 0;
                                int p = 0;
                                int a = 0;
                                for (int day = 1; day <= 31; day++) {
                                  String dKey =
                                      "${_selectedMonth.year}-${m}-${day}_${student.roomNo}_${student.name}";
                                  DailyRecord? rec = getAttendanceMerged(dKey);
                                  if (rec != null) {
                                    if (rec.l == "P")
                                      p++;
                                    else if (rec.l == "A")
                                      a++;
                                    if (rec.d == "P")
                                      p++;
                                    else if (rec.d == "A")
                                      a++;
                                  }
                                }
                                int actual = p * 70;
                                int payable = (p == 0 && a == 0)
                                    ? 0
                                    : calculatePayableBill(p);
                                int due = payable - paid;
                                if (p > 0 || a > 0 || paid > 0) {
                                  d.add([
                                    m.toString(),
                                    p.toString(),
                                    a.toString(),
                                    actual.toString(),
                                    payable.toString(),
                                    paid.toString(),
                                    due.toString(),
                                  ]);
                                }
                              }
                              ExportService.exportReport(
                                context: context,
                                title:
                                    "${student.name} - Yearly ${_selectedMonth.year}",
                                headers: h,
                                data: d,
                                format: "pdf",
                              );
                            },
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
              if (row['status'] == 'Half Paid') statusColor = Colors.green;
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
                              maxLines: 3,
                              overflow: TextOverflow.visible,
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
                            color: brandGreen,
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
                                            await SyncService.pushPaidTargeted(row['monthKey'], val);
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
              backgroundColor: brandGreen,
              title: const Text(
                "Attendance Sheet",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              iconTheme: const IconThemeData(
                color: Colors.white,
              ), // --- TEMPORARY EDITING BLOCK START ---
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  tooltip: "Factory Reset Data",
                  onPressed: _promptResetPassword,
                ),
                if (widget.adminPhone == null || checkAdminPermission(widget.adminPhone!, 'can_attendance_edit'))
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
              ], // --- TEMPORARY EDITING BLOCK END ---
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
            body: TabBarView(
              children: [_buildDailyView(), _buildMonthlyView()],
            ),
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
    Set<String> allKeys = {
      ...globalAttendanceMap.keys,
      ...globalApiAttendanceMap.keys,
    };
    List<String> myKeys = allKeys.where((k) => k.endsWith(suffix)).toList();
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
        backgroundColor: brandGreen,
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
                initialDate: selectedDate ?? realTime,
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
                            maxLines: 3,
                            overflow: TextOverflow.visible,
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
                              color: row['total'] > 0 ? brandGreen : brandGray,
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
        title: const Text(
          "About Developers",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
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
            const SizedBox(height: 16),
            const Text(
              "STUDENTS OF GEC PATAN",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
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
    final emailCtrl = TextEditingController(text: student?.email ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(student == null ? 'Add Student' : 'Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(labelText: 'Room No'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || roomCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name and Room No are required'),
                  ),
                );
                return;
              }
              RegisteredStudent? targetStudent;
              if (student == null) {
                targetStudent = RegisteredStudent(
                  nameCtrl.text,
                  roomCtrl.text,
                  null,
                  '',
                  email: emailCtrl.text.trim(),
                );
                globalRegisteredStudents.add(targetStudent);
              } else {
                int foundIdx = globalRegisteredStudents.indexOf(student);
                if (foundIdx != -1) {
                  targetStudent = RegisteredStudent(
                    nameCtrl.text,
                    roomCtrl.text,
                    student.photoUrl,
                    student.pin,
                    email: emailCtrl.text.trim(),
                  );
                  globalRegisteredStudents[foundIdx] = targetStudent;
                }
              }
              if (targetStudent != null) {
                await SyncService.updateStudentTargeted(targetStudent);
              }
              if (ctx.mounted) Navigator.pop(ctx);
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
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      final words = query.split(RegExp(r'\s+'));
      for (var word in words) {
        if (word.isEmpty) continue;
        if (!s.roomNo.toLowerCase().contains(word) &&
            !s.name.toLowerCase().contains(word)) {
          return false;
        }
      }
      return true;
    }).toList(); // Sort by Room No then Name
    filtered.sort((a, b) {
      int rComp = (int.tryParse(a.roomNo) ?? 0).compareTo(
        int.tryParse(b.roomNo) ?? 0,
      );
      if (rComp != 0) return rComp;
      return a.name.compareTo(b.name);
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Students",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: brandGreen,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(
                      s.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Room: ${s.roomNo} | PIN: ${s.pin == "" ? "Not Set" : "Set (Hidden)"}',
                    ),
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
                                      content: SingleChildScrollView(
                                        child: Column(
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
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dCtx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: deleteText == 'DELETE'
                                              ? () async {
                                                  globalRegisteredStudents
                                                      .remove(s);
                                                   await saveRegisteredStudents();
                                                  await SyncService.pushStudents();
                                                   if (dCtx.mounted) Navigator.pop(dCtx);
                                                }
                                              : null,
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: deleteText == 'DELETE'
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
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
        backgroundColor: brandGreen,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEditDialog(),
      ),
    );
  }
}

