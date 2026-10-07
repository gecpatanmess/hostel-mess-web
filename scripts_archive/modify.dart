import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Remove globalEntryB and globalPollB
  content = content.replaceAll('bool globalEntryB = false;', '');
  content = content.replaceAll('bool globalPollB = false;', '');

  // 2. Update todayPollVotes
  content = content.replaceAll(
    "todayPollVotes = {'B': <String>{}, 'L': <String>{}, 'D': <String>{}};", 
    "todayPollVotes = {'L': <String>{}, 'D': <String>{}};"
  );
  content = content.replaceAll(
    "Map<String, Set<String>> todayPollVotes = {'B': <String>{}, 'L': <String>{}, 'D': <String>{}};", 
    "Map<String, Set<String>> todayPollVotes = {'L': <String>{}, 'D': <String>{}};"
  );

  // 3. Update DailyRecord class
  content = content.replaceAll("String b = ''; // P or A", "");
  content = content.replaceAll("String b = '';", "");
  
  // 4. Update loadSampleAttendanceData
  content = content.replaceAll("rec.b = meals[0];\n    rec.l = meals[1];\n    rec.d = meals[2];", "rec.l = meals[1];\n    rec.d = meals[2];");

  // 5. Update actualBill logic globally
  content = content.replaceAll("if (rec.b == 'P') actualBill += 20;", "");
  content = content.replaceAll("if (rec.l == 'P') actualBill += 60;", "if (rec.l == 'P') actualBill += 70;");
  content = content.replaceAll("if (rec.d == 'P') actualBill += 60;", "if (rec.d == 'P') actualBill += 70;");
  
  content = content.replaceAll("if(rec.b == 'P') actual += 20;", "");
  content = content.replaceAll("if(rec.l == 'P') actual += 60;", "if(rec.l == 'P') actual += 70;");
  content = content.replaceAll("if(rec.d == 'P') actual += 60;", "if(rec.d == 'P') actual += 70;");
  
  content = content.replaceAll("if(rec.b == 'P') dailyTotal += 20;", "");
  content = content.replaceAll("if(rec.l == 'P') dailyTotal += 60;", "if(rec.l == 'P') dailyTotal += 70;");
  content = content.replaceAll("if(rec.d == 'P') dailyTotal += 60;", "if(rec.d == 'P') dailyTotal += 70;");

  // 6. Update present/isP check
  content = content.replaceAll("if (b == 'P' || l == 'P' || d == 'P') presentCount++;", "if (l == 'P' || d == 'P') presentCount++;");
  content = content.replaceAll("bool dayPresent = (rec.b == 'P' || rec.l == 'P' || rec.d == 'P');", "bool dayPresent = (rec.l == 'P' || rec.d == 'P');");
  content = content.replaceAll("bool isP = rec.b == 'P' || rec.l == 'P' || rec.d == 'P';", "bool isP = rec.l == 'P' || rec.d == 'P';");
  
  content = content.replaceAll("if (b == 'P') actualBill += 20;", "");
  content = content.replaceAll("if (l == 'P') actualBill += 60;", "if (l == 'P') actualBill += 70;");
  content = content.replaceAll("if (d == 'P') actualBill += 60;", "if (d == 'P') actualBill += 70;");

  // 7. _loadFakeStudents changes
  String oldFakeStudents = '''// Generate 21 months of history (Jan 2025 to Sep 2026)
      for (int year = 2025; year <= 2026; year++) {
        int maxMonth = (year == 2026) ? 9 : 12;
        for (int month = 1; month <= maxMonth; month++) {
          
          int daysInMonth = DateTime(year, month + 1, 0).day;
          int presentCount = 0;
          int actualBill = 0;
          
          for (int day = 1; day <= daysInMonth; day++) {
            int hash = (seed + year * 12 + month * 31 + day * 7) % 100;
            String b = 'P', l = 'P', d = 'P';
            
            if (hash < 5) { b = 'A'; l = 'A'; d = 'A'; }
            else if (hash < 12) { b = 'A'; l = 'P'; d = 'P'; }
            else if (hash < 19) { b = 'P'; l = 'A'; d = 'P'; }
            else if (hash < 25) { b = 'P'; l = 'P'; d = 'A'; }
            
            if (b == 'P' || l == 'P' || d == 'P') presentCount++;
            if (b == 'P') actualBill += 20;
            if (l == 'P') actualBill += 60;
            if (d == 'P') actualBill += 60;
            
            String key = "\$year-\$month-\${day}_\${room}_\$studentName";
            DailyRecord rec = DailyRecord();
            rec.b = b; rec.l = l; rec.d = d;
            globalAttendanceMap[key] = rec;
          }''';
          
  String newFakeStudents = '''// Generate history (Jan 2026 to Sep 2026)
      for (int year = 2026; year <= 2026; year++) {
        for (int month = 1; month <= 9; month++) {
          
          int daysInMonth = DateTime(year, month + 1, 0).day;
          int presentCount = 0;
          int actualBill = 0;
          
          int targetPresentDays = (seed + month * 7) % 31;
          if (targetPresentDays > daysInMonth) targetPresentDays = daysInMonth;

          for (int day = 1; day <= daysInMonth; day++) {
            String l = 'P', d = 'P';
            
            if (year == 2026 && month == 9) {
              if (day <= targetPresentDays) { l = 'P'; d = 'P'; }
              else { l = 'A'; d = 'A'; }
            } else {
              int hash = (seed + year * 12 + month * 31 + day * 7) % 100;
              if (hash < 5) { l = 'A'; d = 'A'; }
              else if (hash < 12) { l = 'P'; d = 'A'; }
              else if (hash < 19) { l = 'A'; d = 'P'; }
            }
            
            if (l == 'P' || d == 'P') presentCount++;
            if (l == 'P') actualBill += 70;
            if (d == 'P') actualBill += 70;
            
            String key = "\$year-\$month-\${day}_\${room}_\$studentName";
            DailyRecord rec = DailyRecord();
            rec.l = l; rec.d = d;
            globalAttendanceMap[key] = rec;
          }''';
  
  content = content.replaceAll(oldFakeStudents, newFakeStudents);

  file.writeAsStringSync(content);
}
