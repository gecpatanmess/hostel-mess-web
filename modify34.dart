import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // 1. Change global variables: remove globalPaymentStatus, add globalMonthlyPaid
  if (content.contains('Map<String, String> globalPaymentStatus = {};')) {
    content = content.replaceFirst('Map<String, String> globalPaymentStatus = {};', 'Map<String, int> globalMonthlyPaid = {};');
  } else if (!content.contains('Map<String, int> globalMonthlyPaid = {};')) {
    content = content.replaceFirst('Map<String, DailyRecord> globalAttendanceMap = {};', 'Map<String, DailyRecord> globalAttendanceMap = {};\nMap<String, int> globalMonthlyPaid = {};');
  }

  // 2. Replace _loadFakeStudents with the new one
  int startIdx = content.indexOf('void _loadFakeStudents() {');
  int endIdx = content.indexOf('// ===== END SAMPLE DATA =====');
  
  String newFakeStudents = '''void _loadFakeStudents() {
  File dummyPhoto = File('dummy.png');
  
  Map<String, List<String>> realStudents = {
    '101': ['Thakore Yashrajsinh Amitkumar', 'Chaudhary Prins Dineshbhai', 'Shingala Dharm Maheshbhai', 'Aakash Kumar'],
    '102': ['Prajapati Daksh kumar Bhikhabhai', 'Pawan Sharma', 'Satyam Rambahadur Yadav', 'Purvik Kantibhai Chaudhari'],
    '103': ['Prajapati Rakeshkumar Vineshbhai', 'Chaudhary Vijaybhai Meghrajbhai', 'Mali Vipulbhai Dineshbhai', 'Shubham Kumar Singh'],
    '104': ['Chetariya Janak Bhikhubhai', 'Dhruvkumar Hasubhai Parmar', 'Chaudhary Bharat Kanjibhai', 'Rathod Dixitkumar Rameshbhai'],
    '105': ['Chauhan Jay Bharatbhai', 'Pipaliya Yash Rameshbhai', 'Param Rupeshkumar Bariya', 'Radadiya Neel Prafulbhai'],
    '106': ['Choudhary Shivam Anandmohan', 'Aryan Singh', 'Pratik Roshan Patra', 'Manish N Jha'],
    '107': ['Gauravbhai Jayantibhai Makwana', 'Kamlesh Govindbhai Pamak', 'Dhruv Chandrakant Anjani', 'Bhavesh Umesh Kandpal'],
    '108': ['Malaviya Bhavik', 'Rathod Manish Babulal', 'Kushwaha Riteshkumar Harendra', 'Mandal Anmol Ramlal'],
    '109': ['Zala Omdevsinh Sanjaysinh', 'Zala Yashpalsinh', 'Tadvi Mihirkumar', 'Patel Kishan Vinodkumar'],
    '110': ['Parmar Mihir Dineshbhai', 'Prajapati Kunj Bharatbhai', 'Patel Dax Bhaveshkumar', 'Dhandhala Prafulkumar Pravinbhai'],
    '111': ['Bijva Aryan Amarbhai', 'Jadav Deven Maheshbhai', 'Tarun Ganvit', 'Pagi Devang Sanjaybhai'],
    '112': ['Subhranshu Mishra', 'Bhavik Kana Chavda', 'Parth V Karavadra', 'Pal Avanish Bhorik'],
    '113': ['Upadhyay Vishesh Ajay', 'Chaudhary Jayeshbhai Kamabhai', 'Parmar Dhruvkumar Prabhatsinh', 'Mayur Rajarambhai Machhi'],
    '114': ['Akashbhai Dineshbhai Darji', 'Bhautikbhai Virabhanbhai Chaudhary', 'Chaudhary Jagrutbhai Nanjibhai', 'Alpeshkumar Devabhai Chaudhari'],
    '115': ['Sahilkumar Lalbacchan Yadav', 'Kori Bablukumar Omprakash', 'Stephen Jack Abraham Sunder', 'Jha Rohankumar Vijaykumar'],
    '116': ['Nayak Pranayakumar Sanatan', 'Rawat Aditya Dhananjay', 'Rathva Niranjankumar Nareshbhai', 'Abhishek Singh'],
    '117': ['Patel Yashraj Dinkar', 'Singh Ayush Mukesh', 'Baria Kalpeshkumar Jashubhai', 'Golakiya Manav Kamleshbhai'],
    '118': ['Suthar Darshan Sinh J.', 'Patel Yug Dhirubhai', 'Bumtariya Chaitany Satishbhai', 'Singh Atul Anil'],
    '119': ['Vignish Bhat', 'Parmar Shubham Gopalbhai', 'Vansh Pandita', 'Rudra Yogeshkumar Dharva'],
    '120': ['Amarkumar Yadav', 'Chaudhari Jinay Shaileshbhai', 'Pruthviraj Shivrambhai Vasava', 'Maitrik Parmar'],
    '201': ['Chaudhary Srawan Kumar', 'Chaudhary Jitubhai Bhavabhai', 'Yogeshbhai Parmar', 'Adraniya Jigneshji Dasharathji'],
    '202': ['Jehanraj Mittalkumar Chudasama', 'Rehan Siddique', 'Shreshthi Prafulkumar Vishwaratnaji', 'Het Chetankumar Brahmbhatt'],
    '203': ['Padvi Yashilbhai Shukarbhai', 'Vyas Vashishth Mukeshbhai', 'Luhar Sumit Vinodbhai', 'Sudhanshu Kumar'],
    '204': ['Bharadva Priyank Pravinbhai', 'Hingora Arman Osmanbhai', 'Agath Mihir Ranmal', 'Prajapati Jaybhai Jayantibhai'],
    '205': ['Jani Nikhil Sureshbhai', 'Yash Soni', 'Vishal Panchal', 'Vansh Dhamecha'],
    '206': ['Modi Purav Miteshbhai', 'Sathvara Jaykumar Anil Bhai', 'Maurya Abhinay Manoj', 'Chaudhary Milan'],
    '207': ['Dev Yogeshbhai Ahir', 'Patel Krish Ketan', 'Mehta Abhishek Hirenbhai', 'Yadav Harsh Baljeetsingh'],
    '208': ['Dhruv Narendrakumar Solanki', 'Singh Niraj Tejnarayan', 'Jadav Shyam Kalpesh', 'Chaudhari Nirav Jayantikumar'],
    '209': ['Krish Vijaybhai Unagar', 'Charan Parth Satendra', 'Prajapati Kalu Mansukhbhai', 'Gohel Ved Vijaybhai'],
    '210': ['Aditya Pruthvishkumar Brahmakshatriya', 'Damor Utpalkumar Nareshbhai', 'Kaklotar Harsh Shaileshbhai', 'Baraiya Ishvar Rameshbhai'],
    '211': ['Singh Yash Shashivendra', 'Kasela Rushiraj Ashokbhai', 'Rishu Singh', 'Kavad Dhruvil Girdharbhai'],
    '212': ['Chaudhary Dipak Prakash Bhai', 'Hareshbhai Valabhai Asal', 'Vasava Kaushikbhai Vipulbhai', 'Harshit Kumavat'],
    '213': ['Patel Shivoham Tirthram', 'Varma Rahul Jagdishbhai', 'Kamble Mohit Dharmesh', 'Pray Vijaybhai Patel'],
    '214': ['Ahir Dhaivatkumar Prakashbhai', 'Vishvajit Sursinh Solanki', 'Patel Prince Sanjaykumar', 'Solanki Mayur Virajibhai'],
    '215': ['Gaurav Raj', 'Joshi Parv Kashyap', 'Pawar Dakshdeep Jayesh', 'Sharma Kaustuk Ratnesh'],
    '216': ['Dheeraj Pandita', 'Jigar Rajput', 'Kavya Chaudhari', 'Singh Aryan Rakesh'],
    '217': ['Sharma Abhikumar Pankajkumar', 'Patel Jainish Jayesh', 'Rajkumar V. Telee', 'Gelot Dilip Pareshkumar'],
    '218': ['Solanki Sujalkumar Dasharathji', 'Sasmiya Pareshbhai Kantibhai', 'Ladumor Piyush Kalubhai', 'Thakor Yuvrajsing Kamleshsing'],
    '219': ['Satyam Manoj Yadav', 'Chaudhari Yogeshkumar Vajeshibhai', 'Krishkumar Laxmanbhai Chaudhari', 'Joshi Ronak Rameshbhai'],
    '220': ['Rudra Navinbhai Panchal', 'Namra Durgeshchand Tripathi', 'Fakir Shohebsha Badarsha', 'Sukla Utkarsh Vipin'],
  };

  realStudents.forEach((room, names) {
    for (String studentName in names) {
      if (!globalRegisteredStudents.any((st) => st.name == studentName && st.roomNo == room)) {
         globalRegisteredStudents.add(RegisteredStudent(studentName, room, dummyPhoto, '1234'));
      }
      
      int seed = studentName.hashCode;
      
      // Generate 21 months of history (Jan 2025 to Sep 2026)
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
          }
          
          int payableBill = 0;
          if (presentCount == 0) payableBill = 0;
          else if (presentCount <= 22) payableBill = 3080;
          else payableBill = actualBill;
          
          // Payment Logic
          String monthKey = "\$year-\${month}_\${room}_\$studentName";
          int paid = payableBill; // Default fully paid
          
          if (year == 2026 && month == 9) {
            // Current month: mostly unpaid or partially paid
            if (seed % 10 < 3) paid = 0; // Unpaid
            else if (seed % 10 < 6) paid = 2000; // Partially paid
          } else if (year == 2026 && month == 8) {
            // Last month: some unpaid
            if (seed % 100 < 10) paid = 0; 
          }
          
          globalMonthlyPaid[monthKey] = paid;
        }
      }
    }
  });
}
''';
  if (startIdx != -1 && endIdx != -1) {
    content = content.replaceRange(startIdx, endIdx, newFakeStudents);
  }

  // 3. Modify Login Screen to use Dropdown for Names
  // We need to find where the `typedName` textfield is and replace it with a Dropdown if room is selected.
  file.writeAsStringSync(content);
}
