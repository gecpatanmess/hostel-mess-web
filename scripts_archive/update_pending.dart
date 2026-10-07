import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  String newFunc = '''
  List<Map<String, dynamic>> _getPendingDues() {
    List<Map<String, dynamic>> pendingList = [];
    DateTime now = DateTime.now();
    int currentYear = now.year;
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // Check all past months of the current year (up to the current month)
    for (int m = 1; m <= now.month; m++) {
      String monthKeyPrefix = "\$currentYear-\$m";
      String monthName = months[m - 1];

      for (var student in globalRegisteredStudents) {
        String pKey = "\${student.roomNo}_\${student.name}";
        
        int presentCount = 0;
        int absentCount = 0;
        int daysInMonth = 31;
        try {
          daysInMonth = DateTime(currentYear, m + 1, 0).day;
        } catch (e) {}

        for (int d = 1; d <= daysInMonth; d++) {
          String dailyKey = "\${monthKeyPrefix}-\${d}_\$pKey";
          if (globalAttendanceMap.containsKey(dailyKey)) {
            var rec = globalAttendanceMap[dailyKey]!;
            if (rec.l == 'P') presentCount++;
            if (rec.l == 'A') absentCount++;
            if (rec.d == 'P') presentCount++;
            if (rec.d == 'A') absentCount++;
          }
        }

        if (presentCount == 0 && absentCount == 0) continue; 

        int actualBill = presentCount * 70;
        int payableBill = math.max(actualBill, 3080);
        
        String monthPaidKey = "\${monthKeyPrefix}_\$pKey";
        int paidAmt = globalMonthlyPaid[monthPaidKey] ?? 0;

        if (paidAmt < payableBill) {
          pendingList.add({
            'student': student,
            'monthName': monthName,
            'year': currentYear,
            'payable': payableBill,
            'paid': paidAmt,
            'due': payableBill - paidAmt,
          });
        }
      }
    }
    
    // Reverse so most recent months appear first
    return pendingList.reversed.toList();
  }
''';

  // We need to replace the old _getPendingDues function
  content = content.replaceFirst(RegExp(r'List<Map<String, dynamic>> _getPendingDues\(\) \{[\s\S]*?return pendingList;\n  \}'), newFunc.trim());

  // Let's also update the UI title from "Pending Dues (Previous Month)" to "Pending Dues"
  content = content.replaceAll("Pending Dues (Previous Month)", "Pending Dues");

  File('lib/main.dart').writeAsStringSync(content);
}
