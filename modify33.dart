import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  int startIdx = content.indexOf('void _loadFakeStudents() {');
  int endIdx = content.indexOf('// ===== END SAMPLE DATA =====');
  
  if (startIdx != -1 && endIdx != -1) {
    String newContent = '''void _loadFakeStudents() {
  File dummyPhoto = File('dummy.png');
  
  List<String> firstNames = ['Rahul', 'Amit', 'Kiran', 'Vikram', 'Mehul', 'Darshan', 'Rohan', 'Yash', 'Nikhil', 'Chirag', 'Hardik', 'Jay', 'Keval', 'Ravi', 'Suresh', 'Pranav', 'Tushar', 'Dax', 'Arjun', 'Vishal', 'Harsh', 'Deep', 'Mayur', 'Sachin', 'Ankit', 'Gaurav', 'Rohit', 'Manish', 'Aakash', 'Bhavesh', 'Jignesh', 'Sahil', 'Rajesh', 'Vivek', 'Kunal', 'Mohit', 'Parth', 'Neel', 'Dhruv', 'Sagar'];
  List<String> lastNames = ['Patel', 'Shah', 'Desai', 'Joshi', 'Trivedi', 'Parmar', 'Bhatt', 'Pandya', 'Soni', 'Raval', 'Thakur', 'Modi', 'Nagar', 'Kumar', 'Yadav', 'Mehta', 'Dave', 'Sharma', 'Gajjar', 'Vyas', 'Solanki', 'Chauhan', 'Tiwari', 'Rajput', 'Singh', 'Verma', 'Gupta', 'Prajapati', 'Rathod', 'Makwana', 'Khan', 'Sinha', 'Dubey', 'Panchal', 'Agrawal', 'Barot', 'Kothari', 'Chokshi', 'Jain'];
  
  int nameCounter = 0;
  
  List<int> allRooms = [];
  for(int i=101; i<=120; i++) allRooms.add(i);
  for(int i=201; i<=220; i++) allRooms.add(i);

  for (int r in allRooms) {
    String roomStr = r.toString();
    for (int s = 0; s < 4; s++) {
      String fName = firstNames[(nameCounter + s) % firstNames.length];
      String lName = lastNames[(nameCounter + s * 3) % lastNames.length];
      String studentName = "\$fName \$lName";
      nameCounter++;

      // Check if student already exists in globalRegisteredStudents to avoid duplicates if hot reloaded multiple times
      if (!globalRegisteredStudents.any((st) => st.name == studentName && st.roomNo == roomStr)) {
         globalRegisteredStudents.add(RegisteredStudent(studentName, roomStr, dummyPhoto, '1234'));
      }
      
      int seed = studentName.hashCode;
      
      // Generate payment status
      String pStatus = 'Paid';
      if (seed % 10 < 2) pStatus = 'Unpaid';
      else if (seed % 10 < 4) pStatus = 'Half Paid';
      String monthKey = "2026-9_\${roomStr}_\$studentName";
      globalPaymentStatus[monthKey] = pStatus;

      // Generate 30 days of data for September
      for (int day = 1; day <= 30; day++) {
        int hash = (seed + day * 7) % 100;
        String b, l, d;
        // High probability of eating all meals, some probability of skipping
        if (hash < 10) { b = 'A'; l = 'A'; d = 'A'; }
        else if (hash < 20) { b = 'P'; l = 'A'; d = 'P'; }
        else if (hash < 30) { b = 'A'; l = 'P'; d = 'P'; }
        else if (hash < 40) { b = 'P'; l = 'P'; d = 'A'; }
        else { b = 'P'; l = 'P'; d = 'P'; }
        
        String key = "2026-9-\${day}_\${roomStr}_\$studentName";
        DailyRecord rec = DailyRecord();
        rec.b = b; rec.l = l; rec.d = d;
        globalAttendanceMap[key] = rec;
      }
    }
  }
}
''';
    content = content.replaceRange(startIdx, endIdx, newContent);
    file.writeAsStringSync(content);
  }
}
