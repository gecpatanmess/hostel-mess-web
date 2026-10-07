import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // Add sample data function after globalAttendanceMap declaration
  String sampleData = '''
// ===== SAMPLE DATA FOR TESTING (REMOVE LATER) =====
void loadSampleAttendanceData(String roomNo, String name) {
  Map<String, List<String>> sampleDays = {
    '2026-9-1': ['P', 'P', 'P'],   // B, L, D - Full day
    '2026-9-2': ['P', 'P', 'A'],   // Skipped dinner
    '2026-9-3': ['A', 'P', 'P'],   // Skipped breakfast
    '2026-9-4': ['P', 'A', 'A'],   // Only breakfast
    '2026-9-5': ['A', 'A', 'A'],   // Absent full day
    '2026-9-6': ['P', 'P', 'P'],   // Full day
    '2026-9-7': ['P', 'P', 'P'],   // Full day
    '2026-9-8': ['A', 'A', 'A'],   // Absent full day
    '2026-9-9': ['P', 'A', 'P'],   // Skipped lunch
    '2026-9-10': ['P', 'P', 'P'],  // Full day
    '2026-9-11': ['P', 'P', 'A'],  // Skipped dinner
    '2026-9-12': ['A', 'P', 'P'],  // Skipped breakfast
    '2026-9-13': ['P', 'P', 'P'],  // Full day
    '2026-9-14': ['A', 'A', 'A'],  // Absent full day
    '2026-9-15': ['P', 'P', 'P'],  // Full day
    '2026-9-16': ['P', 'A', 'P'],  // Skipped lunch
    '2026-9-17': ['P', 'P', 'P'],  // Full day
    '2026-9-18': ['A', 'P', 'P'],  // Skipped breakfast
    '2026-9-19': ['P', 'P', 'P'],  // Full day
    '2026-9-20': ['P', 'P', 'A'],  // Skipped dinner
    '2026-9-21': ['A', 'A', 'A'],  // Absent full day
    '2026-9-22': ['P', 'P', 'P'],  // Full day
    '2026-9-23': ['P', 'A', 'P'],  // Skipped lunch
    '2026-9-24': ['P', 'P', 'P'],  // Full day
  };
  sampleDays.forEach((date, meals) {
    String key = "\${date}_\${roomNo}_\${name}";
    DailyRecord rec = DailyRecord();
    rec.b = meals[0];
    rec.l = meals[1];
    rec.d = meals[2];
    globalAttendanceMap[key] = rec;
  });
}
// ===== END SAMPLE DATA =====
''';

  // Insert after globalAttendanceMap declaration
  String target = 'Map<String, DailyRecord> globalAttendanceMap = {};';
  content = content.replaceFirst(target, target + '\n' + sampleData);

  // Call loadSampleAttendanceData when student logs in (inside _handleStudentLogin)
  String oldNav = '''    Navigator.pushReplacement(
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

  String newNav = '''    // Load sample data for testing (REMOVE LATER)
    loadSampleAttendanceData(selectedRoom!, typedName);

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

  content = content.replaceFirst(oldNav, newNav);

  file.writeAsStringSync(content);
}
