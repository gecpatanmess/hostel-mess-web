import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  String newFunc = '''
  List<Map<String, dynamic>> _getPendingDues() {
    List<Map<String, dynamic>> pendingList = [];
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    Map<String, Map<String, int>> studentMonthStats = {};

    globalAttendanceMap.forEach((key, rec) {
      List<String> parts = key.split('_');
      if (parts.length >= 3) {
        String datePart = parts[0]; 
        String room = parts[1];
        String name = parts[2];
        
        List<String> dateParts = datePart.split('-');
        if (dateParts.length >= 3) {
          String year = dateParts[0];
          String month = dateParts[1];
          String groupKey = "\$year-\$month_\${room}_\$name";

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

      List<String> ymParts = yearMonth.split('-');
      String year = ymParts[0];
      int mIdx = int.tryParse(ymParts[1]) ?? 1;
      String monthName = months[mIdx - 1];

      int actualBill = counts['P']! * 70;
      int payableBill = math.max(actualBill, 3080);

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
''';

  content = content.replaceFirst(RegExp(r'List<Map<String, dynamic>> _getPendingDues\(\) \{[\s\S]*?return pendingList\.reversed\.toList\(\);\n  \}'), newFunc.trim());

  File('lib/main.dart').writeAsStringSync(content);
}
