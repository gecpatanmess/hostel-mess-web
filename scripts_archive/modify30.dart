import 'dart:io';
import 'dart:math';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // Replace the old loadSampleAttendanceData function with a bigger one that adds multiple students
  String oldFunc = '''// ===== SAMPLE DATA FOR TESTING (REMOVE LATER) =====
void loadSampleAttendanceData(String roomNo, String name) {''';

  String newFunc = '''// ===== SAMPLE DATA FOR TESTING (REMOVE LATER) =====
bool _sampleDataLoaded = false;
void loadSampleAttendanceData(String roomNo, String name) {
  if (!_sampleDataLoaded) {
    _sampleDataLoaded = true;
    _loadFakeStudents();
  }''';

  content = content.replaceFirst(oldFunc, newFunc);

  // Add the _loadFakeStudents function after the closing of loadSampleAttendanceData
  String endMarker = '// ===== END SAMPLE DATA =====';

  String fakeStudentsFunc = '''
void _loadFakeStudents() {
  File dummyPhoto = File('dummy.png');
  
  Map<String, List<String>> fakeStudents = {
    '101': ['Rahul Patel', 'Amit Shah', 'Kiran Desai', 'Vikram Joshi'],
    '102': ['Mehul Trivedi', 'Darshan Parmar', 'Rohan Bhatt'],
    '103': ['Yash Pandya', 'Nikhil Soni', 'Chirag Raval', 'Hardik Thakur'],
    '105': ['Jay Modi', 'Keval Nagar'],
    '108': ['Ravi Kumar', 'Suresh Yadav', 'Pranav Mehta', 'Tushar Dave'],
    '110': ['Dax Patel', 'Arjun Sharma', 'Vishal Gajjar'],
    '115': ['Harsh Vyas', 'Deep Solanki', 'Mayur Chauhan', 'Sachin Tiwari'],
    '201': ['Ankit Rajput', 'Gaurav Singh', 'Rohit Verma'],
    '205': ['Manish Gupta', 'Aakash Prajapati', 'Bhavesh Rathod', 'Jignesh Makwana'],
    '210': ['Sahil Khan', 'Rajesh Sinha'],
    '215': ['Vivek Dubey', 'Kunal Panchal', 'Mohit Agrawal'],
    '220': ['Parth Barot', 'Neel Kothari', 'Dhruv Chokshi', 'Sagar Jain'],
  };

  List<String> statuses = ['P', 'A'];
  
  fakeStudents.forEach((room, names) {
    for (String studentName in names) {
      globalRegisteredStudents.add(RegisteredStudent(studentName, room, dummyPhoto, '1234'));
      
      int seed = studentName.hashCode;
      for (int day = 1; day <= 25; day++) {
        int hash = (seed + day * 7) % 100;
        String b, l, d;
        if (hash < 15) {
          b = 'A'; l = 'A'; d = 'A';
        } else if (hash < 30) {
          b = 'P'; l = 'A'; d = 'P';
        } else if (hash < 45) {
          b = 'A'; l = 'P'; d = 'P';
        } else if (hash < 60) {
          b = 'P'; l = 'P'; d = 'A';
        } else {
          b = 'P'; l = 'P'; d = 'P';
        }
        String key = "2026-9-\$day\_\${room}_\$studentName";
        DailyRecord rec = DailyRecord();
        rec.b = b; rec.l = l; rec.d = d;
        globalAttendanceMap[key] = rec;
      }
    }
  });
}

''';

  content = content.replaceFirst(endMarker, fakeStudentsFunc + endMarker);

  file.writeAsStringSync(content);
}
