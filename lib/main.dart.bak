import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for inputFormatters
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

String formatDateTime(DateTime dt) {
  String pad(int n) => n.toString().padLeft(2, '0');
  String period = dt.hour >= 12 ? 'PM' : 'AM';
  int hour12 = dt.hour % 12;
  if (hour12 == 0) hour12 = 12;
  return "${pad(dt.day)}/${pad(dt.month)}/${dt.year} | ${pad(hour12)}:${pad(dt.minute)} $period";
}

class ViewMenuTab extends StatelessWidget {
  const ViewMenuTab({super.key});
  @override
  Widget build(BuildContext context) {
    if (globalMenuFile == null) {
      return const Center(child: Text("No menu uploaded yet.", style: TextStyle(color: brandGray)));
    }
    if (globalMenuIsPdf) {
      return SfPdfViewer.file(globalMenuFile!);
    } else {
      return InteractiveViewer(child: Center(child: Image.file(globalMenuFile!)));
    }
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
  final File studentPhoto;
  ComplaintItem(this.id, this.title, this.description, this.date, this.studentName, this.studentRoom, this.studentPhoto);
}
List<ComplaintItem> globalComplaints = [];
Set<String> globalStudentHiddenComplaints = {};
Set<String> globalStudentHiddenNotices = {};
DateTime globalStudentLastViewedNotices = DateTime(2000);
Set<String> globalAdminHiddenComplaints = {};
Set<String> globalAdminHiddenNotices = {};
class RegisteredStudent {
  final String name;
  final String roomNo;
  final File photo;
  final String pin;
  RegisteredStudent(this.name, this.roomNo, this.photo, this.pin);
}
List<RegisteredStudent> globalRegisteredStudents = [];

bool globalEntryB = false;
bool globalEntryL = false;
bool globalEntryD = false;
bool globalPollB = false;
bool globalPollL = false;
bool globalPollD = false;
String globalPollDate = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
void checkAndResetPoll() {
  String todayStr = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
  if (globalPollDate != todayStr) {
    todayPollVotes = {'B': <String>{}, 'L': <String>{}, 'D': <String>{}};
    globalPollB = false;
    globalPollL = false;
    globalPollD = false;
    globalPollDate = todayStr;
  }
}

Map<String, Set<String>> todayPollVotes = {'B': <String>{}, 'L': <String>{}, 'D': <String>{}};

class DailyRecord {
  String b = ''; // P or A
  String l = '';
  String d = '';
}
Map<String, DailyRecord> globalAttendanceMap = {};
Map<String, int> globalMonthlyPaid = {};
// ===== SAMPLE DATA FOR TESTING (REMOVE LATER) =====
bool _sampleDataLoaded = false;
void loadSampleAttendanceData(String roomNo, String name) {
  if (!_sampleDataLoaded) {
    _sampleDataLoaded = true;
    _loadFakeStudents();
  }
  Map<String, List<String>> sampleDays = {
    '2026-9-1': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-2': ['P', 'P', 'A'],   // Skipped dinner = 80
    '2026-9-3': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-4': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-5': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-6': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-7': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-8': ['A', 'P', 'P'],   // Skipped breakfast = 120
    '2026-9-9': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-10': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-11': ['P', 'P', 'A'],  // Skipped dinner = 80
    '2026-9-12': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-13': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-14': ['A', 'A', 'A'],  // Absent full day = 0
    '2026-9-15': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-16': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-17': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-18': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-19': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-20': ['P', 'A', 'P'],  // Skipped lunch = 80
    '2026-9-21': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-22': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-23': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-24': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-25': ['P', 'P', 'P'],  // Full day = 140
  };
  sampleDays.forEach((date, meals) {
    String key = "${date}_${roomNo}_${name}";
    DailyRecord rec = DailyRecord();
    rec.b = meals[0];
    rec.l = meals[1];
    rec.d = meals[2];
    globalAttendanceMap[key] = rec;
  });
}
void _loadFakeStudents() {
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
            
            String key = "$year-$month-${day}_${room}_$studentName";
            DailyRecord rec = DailyRecord();
            rec.b = b; rec.l = l; rec.d = d;
            globalAttendanceMap[key] = rec;
          }
          
          int payableBill = 0;
          if (presentCount == 0) payableBill = 0;
          else if (presentCount <= 22) payableBill = 3080;
          else payableBill = actualBill;
          
          // Payment Logic
          String monthKey = "$year-${month}_${room}_$studentName";
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
// ===== END SAMPLE DATA =====



File? globalMenuFile;
bool globalMenuIsPdf = false;

DateTime globalAdminLastViewedComplaints = DateTime(2000);

void main() {
  _loadFakeStudents();
  runApp(const MyApp());
}

// Global Brand Colors for consistency
const Color brandOrange = Color(0xFFB74300);
const Color brandBg = Color(0xFFF6F8FC);
const Color brandInputBg = Color(0xFFEFF3FC);
const Color brandDark = Color(0xFF0F172A);
const Color brandGray = Color(0xFF64748B);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hostel Mess Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins', 
        primaryColor: brandOrange,
        scaffoldBackgroundColor: brandBg,
        colorScheme: ColorScheme.fromSeed(seedColor: brandOrange),
      ),
      home: const LoginScreen(),
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
  bool isStudentPinVisible = false;
  bool isAdminPassVisible = false;
  String? selectedStudentName;

  final _studentFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  // Controllers to fetch data
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentPinController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _adminMobileController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();

  File? studentPhoto;
  File? adminPhoto;
  final ImagePicker _picker = ImagePicker();

  String? selectedRoom;
  final List<String> roomNumbers = [
    for (int i = 101; i <= 120; i++) i.toString(),
    for (int i = 201; i <= 220; i++) i.toString(),
  ];

  Future<void> _pickImage(bool isStudentForm) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isStudentForm) {
          studentPhoto = File(image.path);
        } else {
          adminPhoto = File(image.path);
        }
      });
    }
  }

  void _handleStudentLogin() {
    if (!_studentFormKey.currentState!.validate()) return;
    if (selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a room'), backgroundColor: Colors.redAccent));
      return;
    }
    if (selectedStudentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your name'), backgroundColor: Colors.redAccent));
      return;
    }

    String typedName = selectedStudentName!;
    String typedPin = _studentPinController.text.trim();
    
    var roomStudents = globalRegisteredStudents.where((s) => s.roomNo == selectedRoom!).toList();
    RegisteredStudent? existingStudent;
    try {
      existingStudent = roomStudents.firstWhere((s) => s.name.toLowerCase() == typedName.toLowerCase());
    } catch (e) {
      existingStudent = null;
    }

    if (existingStudent != null) {
      if (existingStudent.pin != typedPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Wrong PIN! Please enter the correct PIN.', style: TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.redAccent)
        );
        return;
      }
      if (studentPhoto == null) {
        studentPhoto = existingStudent.photo;
      }
    } else {
      if (studentPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Please upload a student photo for new registration.', style: TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.redAccent)
        );
        return;
      }
      if (roomStudents.length >= 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('આ રૂમ ફૂલ થઈ ગયો છે (Max 4 students).', style: TextStyle(fontWeight: FontWeight.w600)), backgroundColor: Colors.redAccent)
        );
        return;
      }
      globalRegisteredStudents.add(RegisteredStudent(typedName, selectedRoom!, studentPhoto!, typedPin));
    }


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
  }

  void _handleAdminLogin() {
    if (adminPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload an admin photo', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (_adminFormKey.currentState!.validate()) {
      // Admin Hardcoded Credentials Check
      if (_adminMobileController.text.trim() == "9586401483" && _adminPasswordController.text == "dax123") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboardScreen(
              photo: adminPhoto!,
              name: _adminNameController.text,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid Mobile Number or Password', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: brandDark, letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Smart Dining, Attendance & Digital Mess Entry",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: brandGray, fontWeight: FontWeight.w500, letterSpacing: 0.2),
              ),
              const SizedBox(height: 32),

              // Tab Switcher
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: brandInputBg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isStudent = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isStudent ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isStudent ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))] : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school, size: 20, color: isStudent ? brandOrange : brandGray),
                              const SizedBox(width: 8),
                              Text("Student", style: TextStyle(fontSize: 14, fontWeight: isStudent ? FontWeight.w600 : FontWeight.w500, color: isStudent ? brandOrange : brandGray)),
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
                            color: !isStudent ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: !isStudent ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))] : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.security, size: 20, color: !isStudent ? brandOrange : brandGray),
                              const SizedBox(width: 8),
                              Text("Admin", style: TextStyle(fontSize: 14, fontWeight: !isStudent ? FontWeight.w600 : FontWeight.w500, color: !isStudent ? brandOrange : brandGray)),
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
                  return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(animation), child: child));
                },
                child: isStudent ? _buildStudentPortal() : _buildAdminPortal(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentPortal() {
    return Container(
      key: const ValueKey("StudentPortal"),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
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
                Text("Student Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark))
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE9D2),
                            shape: BoxShape.circle,
                            image: studentPhoto != null ? DecorationImage(image: FileImage(studentPhoto!), fit: BoxFit.cover) : null,
                          ),
                          child: studentPhoto == null ? const Icon(Icons.camera_alt_outlined, color: brandOrange, size: 38) : null,
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
                              border: Border.all(color: Colors.white, width: 3.0),
                              boxShadow: [BoxShadow(color: brandOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Upload Student Photo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildDropdownField(),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Full Name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: brandInputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedStudentName,
                    hint: const Text("Select Name", style: TextStyle(color: brandGray, fontSize: 14)),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined, color: brandGray),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: selectedRoom == null ? [] : globalRegisteredStudents
                        .where((s) => s.roomNo == selectedRoom)
                        .map((e) => e.name)
                        .toSet()
                        .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedStudentName = val;
                      });
                    },
                    validator: (val) => val == null ? "Please select your name" : null,
                  ),
                ),
              ]
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              controller: _studentPinController,
              label: "4 Digit - PIN",
              hintText: "Enter 4 - digit PIN",
              icon: Icons.dialpad,
              isStudent: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4), // strictly limits to 4 digits
              ],
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _handleStudentLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Student Login", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            )
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
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
                Text("Admin Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark))
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
                            image: adminPhoto != null ? DecorationImage(image: FileImage(adminPhoto!), fit: BoxFit.cover) : null,
                          ),
                          child: adminPhoto == null ? const Icon(Icons.person_outline, color: brandOrange, size: 42) : null,
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
                              border: Border.all(color: Colors.white, width: 3.0),
                              boxShadow: [BoxShadow(color: brandOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Upload Admin Photo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
            const SizedBox(height: 20),
            _buildPasswordField(
              controller: _adminPasswordController,
              label: "Secure Password",
              hintText: "Enter your password",
              icon: Icons.lock_outline,
              isStudent: false,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _handleAdminLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Admin Login", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.login, size: 20),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Room Number", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          validator: (value) => (value == null || value.isEmpty) ? 'Please select a room' : null,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.door_front_door_outlined, color: brandGray, size: 22),
            filled: true,
            fillColor: brandInputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down, color: brandGray),
          hint: Text("Select your room", style: TextStyle(color: brandGray.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.normal)),
          value: selectedRoom,
          items: roomNumbers.map((String room) {
            return DropdownMenuItem<String>(value: room, child: Text(room, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: brandDark)));
          }).toList(),
          onChanged: (String? newValue) => setState(() => selectedRoom = newValue),
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter $label' : null,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: brandGray.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: brandGray, size: 22),
            filled: true,
            fillColor: brandInputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
          ),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: brandDark),
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: !isVisible,
          obscuringCharacter: '●',
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Please enter $label';
            if (isStudent && value.trim().length != 4) return 'PIN must be exactly 4 digits';
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: brandGray.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.normal, letterSpacing: 0),
            prefixIcon: Icon(icon, color: brandGray, size: 22),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, color: brandGray, size: 22),
              onPressed: () => setState(() {
                if (isStudent) { isStudentPinVisible = !isStudentPinVisible; } 
                else { isAdminPassVisible = !isAdminPassVisible; }
              }),
            ),
            filled: true,
            fillColor: brandInputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
          ),
          style: TextStyle(fontSize: isVisible ? 15 : 18, letterSpacing: isVisible ? 0 : 4, fontWeight: FontWeight.w500, color: brandDark),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// STUDENT DASHBOARD SCREEN
// -----------------------------------------------------------------------------
class StudentDashboardScreen extends StatefulWidget {
  final File photo;
  final String name;
  final String roomNo;

  const StudentDashboardScreen({super.key, required this.photo, required this.name, required this.roomNo});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;
  bool _pollCheckB = false;
  bool _pollCheckL = false;
  bool _pollCheckD = false;
  DateTime _attendanceMonth = DateTime(DateTime.now().year, DateTime.now().month);


    Widget _buildHomeTab() {
    String activeMeal = '';
    if (globalEntryB) activeMeal = 'Breakfast';
    else if (globalEntryL) activeMeal = 'Lunch';
    else if (globalEntryD) activeMeal = 'Dinner';

    DateTime now = DateTime.now();
    String key = "${now.year}-${now.month}-${now.day}_${widget.roomNo}_${widget.name}";
    DailyRecord todayRecord = globalAttendanceMap[key] ?? DailyRecord();

    bool hasAction = false;
    String statusStr = "";
    if (activeMeal == 'Breakfast' && todayRecord.b.isNotEmpty) { hasAction = true; statusStr = todayRecord.b; }
    if (activeMeal == 'Lunch' && todayRecord.l.isNotEmpty) { hasAction = true; statusStr = todayRecord.l; }
    if (activeMeal == 'Dinner' && todayRecord.d.isNotEmpty) { hasAction = true; statusStr = todayRecord.d; }

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
                        Text("Mess Entry", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
                      ]
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}", style: const TextStyle(color: brandOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                    )
                  ]
                ),
                const Divider(height: 32),
                if (activeMeal.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text("Mess is currently closed.\nPlease wait for the next meal to start.", textAlign: TextAlign.center, style: TextStyle(color: brandGray, fontSize: 16)),
                    ),
                  )
                else ...[
                  Center(child: Text("🍽️ $activeMeal Time is Active", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
                  const SizedBox(height: 24),
                  if (hasAction)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: (statusStr == 'P' ? Colors.green : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusStr == 'P' ? Icons.check_circle : Icons.cancel, color: statusStr == 'P' ? Colors.green : Colors.redAccent),
                          const SizedBox(width: 8),
                          Text(statusStr == 'P' ? "Attendance marked!" : "Meal Skipped", style: TextStyle(color: statusStr == 'P' ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold))
                        ]
                      )
                    )
                  else
                    Column(
                      children: [
                        SwipeToConfirm(
                          text: "Swipe for $activeMeal",
                          onConfirm: () {
                            setState(() {
                              globalAttendanceMap.putIfAbsent(key, () => DailyRecord());
                              if (activeMeal == 'Breakfast') globalAttendanceMap[key]!.b = 'P';
                              else if (activeMeal == 'Lunch') globalAttendanceMap[key]!.l = 'P';
                              else if (activeMeal == 'Dinner') globalAttendanceMap[key]!.d = 'P';
                            });
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(
                              mealName: activeMeal,
                              photo: widget.photo,
                              name: widget.name,
                              roomNo: widget.roomNo
                            )));
                          }
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              globalAttendanceMap.putIfAbsent(key, () => DailyRecord());
                              if (activeMeal == 'Breakfast') globalAttendanceMap[key]!.b = 'A';
                              else if (activeMeal == 'Lunch') globalAttendanceMap[key]!.l = 'A';
                              else if (activeMeal == 'Dinner') globalAttendanceMap[key]!.d = 'A';
                            });
                          },
                          icon: const Icon(Icons.no_meals, color: Colors.redAccent),
                          label: const Text("Skip Meal", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                        )
                      ]
                    )
                ]
              ],
            ),
          ),
        ),
        _buildPollCard(),
        _buildAttendanceCard()
      ],
    );
  }

  Widget _buildAttendanceCard() {
    int currentMonth = _attendanceMonth.month;
    int currentYear = _attendanceMonth.year;
    String suffix = "_${widget.roomNo}_${widget.name}";
    
    List<String> monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    int presentDays = 0;
    int absentDays = 0;
    int actualBill = 0;
    
    globalAttendanceMap.forEach((key, rec) {
      if (!key.endsWith(suffix)) return;
      String datePart = key.split('_')[0];
      List<String> parts = datePart.split('-');
      int y = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      if (y != currentYear || m != currentMonth) return;
      
      bool dayPresent = (rec.b == 'P' || rec.l == 'P' || rec.d == 'P');
      if (dayPresent) {
        presentDays++;
      } else {
        absentDays++;
      }
      
      if (rec.b == 'P') actualBill += 20;
      if (rec.l == 'P') actualBill += 60;
      if (rec.d == 'P') actualBill += 60;
    });
    
    int payableBill;
    bool minRuleApplied = false;
    if (presentDays == 0 && absentDays == 0) {
      payableBill = 0;
    } else if (presentDays <= 22) {
      payableBill = 3080;
      minRuleApplied = true;
    } else {
      payableBill = actualBill;
    }

    String monthKey = "${currentYear}-${currentMonth}${suffix}";
    int paidAmt = globalMonthlyPaid[monthKey] ?? 0;
    int dueAmt = payableBill - paidAmt;
    if (dueAmt < 0) dueAmt = 0;

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
            const Row(
              children: [
                Icon(Icons.bar_chart, color: brandOrange),
                SizedBox(width: 8),
                Text("📊 My Attendance & Billing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
              ]
            ),
            const Divider(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: brandDark),
                  onPressed: () {
                    setState(() {
                      _attendanceMonth = DateTime(
                        _attendanceMonth.month == 1 ? _attendanceMonth.year - 1 : _attendanceMonth.year,
                        _attendanceMonth.month == 1 ? 12 : _attendanceMonth.month - 1
                      );
                    });
                  }
                ),
                Text(
                  "${monthNames[currentMonth]} $currentYear",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: brandDark),
                  onPressed: () {
                    DateTime now = DateTime.now();
                    if (_attendanceMonth.year < now.year || (_attendanceMonth.year == now.year && _attendanceMonth.month < now.month)) {
                      setState(() {
                        _attendanceMonth = DateTime(
                          _attendanceMonth.month == 12 ? _attendanceMonth.year + 1 : _attendanceMonth.year,
                          _attendanceMonth.month == 12 ? 1 : _attendanceMonth.month + 1
                        );
                      });
                    }
                  }
                ),
              ]
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 28),
                        const SizedBox(height: 8),
                        Text("$presentDays", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                        const Text("Present", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]
                    )
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cancel, color: Colors.redAccent, size: 28),
                        const SizedBox(height: 8),
                        Text("$absentDays", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        const Text("Absent", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]
                    )
                  )
                ),
              ]
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: brandOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text("Payable Bill", style: TextStyle(color: brandDark, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("₹$payableBill", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandOrange)),
                        if (minRuleApplied)
                          const Text("(Min 22-day rule)", style: TextStyle(color: brandGray, fontSize: 10)),
                      ]
                    )
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text("Actual Bill", style: TextStyle(color: brandDark, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("₹$actualBill", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const Text("(Real cost)", style: TextStyle(color: brandGray, fontSize: 10)),
                      ]
                    )
                  )
                ),
              ]
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentAttendanceScreen(name: widget.name, roomNo: widget.roomNo)));
                },
                icon: const Icon(Icons.visibility, color: brandOrange, size: 18),
                label: const Text("View Full Details", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: brandOrange),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            )
          ]
        )
      )
    );
  }

  Widget _buildPollOption(String title, bool canVote, bool val, Function(bool?) onChanged) {
    if (!canVote) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough))
          ],
        ),
      );
    }
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      value: val,
      activeColor: brandOrange,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: onChanged,
    );
  }

  Widget _buildPollCard() {
    checkAndResetPoll();
    String studentKey = "${widget.roomNo}_${widget.name}";
    bool votedB = todayPollVotes['B']!.contains(studentKey);
    bool votedL = todayPollVotes['L']!.contains(studentKey);
    bool votedD = todayPollVotes['D']!.contains(studentKey);

    bool canVoteB = globalPollB && !votedB;
    bool canVoteL = globalPollL && !votedL;
    bool canVoteD = globalPollD && !votedD;

    bool hasPendingVote = canVoteB || canVoteL || canVoteD;

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
            const Row(
              children: [
                Icon(Icons.poll, color: brandOrange),
                SizedBox(width: 8),
                Text("📝 Today's Mess Poll", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
              ]
            ),
            const Divider(height: 32),
            
            if (!globalPollB && !globalPollL && !globalPollD)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text("No polls are currently active.", style: TextStyle(color: brandGray, fontSize: 16)),
                ),
              )
            else ...[
              if (globalPollB) _buildPollOption("Breakfast", canVoteB, _pollCheckB, (v) => setState(() => _pollCheckB = v!)),
              if (globalPollL) _buildPollOption("Lunch", canVoteL, _pollCheckL, (v) => setState(() => _pollCheckL = v!)),
              if (globalPollD) _buildPollOption("Dinner", canVoteD, _pollCheckD, (v) => setState(() => _pollCheckD = v!)),

              if (hasPendingVote) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!_pollCheckB && !_pollCheckL && !_pollCheckD) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one meal!'), backgroundColor: Colors.redAccent));
                         return;
                      }
                      setState(() {
                        if (_pollCheckB) todayPollVotes['B']!.add(studentKey);
                        if (_pollCheckL) todayPollVotes['L']!.add(studentKey);
                        if (_pollCheckD) todayPollVotes['D']!.add(studentKey);
                        _pollCheckB = false; _pollCheckL = false; _pollCheckD = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poll Submitted Successfully!'), backgroundColor: Colors.green));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: brandOrange, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Submit Vote", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  )
                )
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Thanks for voting!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                    ]
                  )
                )
              ]
            ]
          ]
        )
      )
    );
  }

  Widget _buildNoticeTab() {
    final visibleNotices = globalNotices.where((n) => !globalStudentHiddenNotices.contains(n.id)).toList();
    
    return visibleNotices.isEmpty
        ? const Center(child: Text("No new notices.", style: TextStyle(color: brandGray)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visibleNotices.length,
            itemBuilder: (context, index) {
              final notice = visibleNotices[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFDE9D2), child: Icon(Icons.notifications, color: brandOrange)),
                  title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notice.message, style: const TextStyle(color: brandGray)),
                      const SizedBox(height: 8),
                      Text(formatDateTime(notice.date), style: const TextStyle(fontSize: 11, color: brandOrange, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      setState(() { globalStudentHiddenNotices.add(notice.id); });
                    },
                  ),
                ),
              );
            },
          );
  }

  void _onLogout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: const Text("Student Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: brandOrange),
              accountName: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text("Room: ${widget.roomNo}"),
              currentAccountPicture: CircleAvatar(
                backgroundImage: FileImage(widget.photo),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.co_present, color: brandDark),
              title: const Text('My Attendance', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => StudentAttendanceScreen(name: widget.name, roomNo: widget.roomNo)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: brandDark),
              title: const Text('Long Leave', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined, color: brandDark),
              title: const Text('Mess Complaints', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => StudentComplaintsScreen(
                  name: widget.name,
                  roomNo: widget.roomNo,
                  photo: widget.photo,
                )));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('LogOut', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
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
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 36, backgroundImage: FileImage(widget.photo)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome Back,", style: TextStyle(color: brandGray, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(widget.name, style: const TextStyle(color: brandDark, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text("Room: ${widget.roomNo}", style: const TextStyle(color: brandOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                      )
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
          )
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
              isLabelVisible: globalNotices.where((n) => !globalStudentHiddenNotices.contains(n.id) && n.date.isAfter(globalStudentLastViewedNotices)).isNotEmpty,
              label: Text(globalNotices.where((n) => !globalStudentHiddenNotices.contains(n.id) && n.date.isAfter(globalStudentLastViewedNotices)).length.toString()),
              child: const Icon(Icons.notifications),
            ),
            label: "View Notice",
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: "View Menu"),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ADMIN DASHBOARD SCREEN
// -----------------------------------------------------------------------------
class AdminDashboardScreen extends StatefulWidget {
  final File photo;
  final String name;

  const AdminDashboardScreen({super.key, required this.photo, required this.name});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  Widget _buildAdminHomeTab() {
    checkAndResetPoll();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("📊 Live Poll Results", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          todayPollVotes = {'B': <String>{}, 'L': <String>{}, 'D': <String>{}};
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poll data cleared!')));
                      },
                      icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                      label: const Text("Clear", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                    )
                  ]
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(children: [const Icon(Icons.free_breakfast, color: brandOrange), const SizedBox(height: 4), Text("${todayPollVotes['B']!.length}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Text("Breakfast", style: TextStyle(color: brandGray, fontSize: 12))]),
                      Column(children: [const Icon(Icons.lunch_dining, color: brandOrange), const SizedBox(height: 4), Text("${todayPollVotes['L']!.length}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Text("Lunch", style: TextStyle(color: brandGray, fontSize: 12))]),
                      Column(children: [const Icon(Icons.dinner_dining, color: brandOrange), const SizedBox(height: 4), Text("${todayPollVotes['D']!.length}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Text("Dinner", style: TextStyle(color: brandGray, fontSize: 12))]),
                    ]
                  )
                )
              ]
            )
          )
        ),
      ],
    );
  }




  Widget _buildNoticeTab() {
    final visibleNotices = globalNotices.where((n) => !globalAdminHiddenNotices.contains(n.id)).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: visibleNotices.isEmpty
          ? const Center(child: Text("No notices yet. Click + to add one.", style: TextStyle(color: brandGray)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visibleNotices.length,
              itemBuilder: (context, index) {
                final notice = visibleNotices[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notice.message, style: const TextStyle(color: brandGray)),
                        const SizedBox(height: 8),
                        Text(formatDateTime(notice.date), style: const TextStyle(fontSize: 11, color: brandOrange, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        setState(() { globalAdminHiddenNotices.add(notice.id); });
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
        title: const Text("New Notice", style: TextStyle(color: brandDark, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl, 
              decoration: InputDecoration(
                labelText: "Notice Title", 
                filled: true, fillColor: brandInputBg, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              )
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl, 
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Message", 
                filled: true, fillColor: brandInputBg, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: brandGray))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                setState(() {
                  globalNotices.insert(0, NoticeItem(
                    DateTime.now().toString(),
                    titleCtrl.text,
                    msgCtrl.text,
                    DateTime.now(),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Send Notice", style: TextStyle(color: Colors.white)),
          )
        ]
      )
    );
  }


  void _onLogout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  void _showSetMenuDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Set Menu", style: TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (globalMenuFile == null)
                    InkWell(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                        );
                        if (result != null && result.files.single.path != null) {
                          setDialogState(() {
                            globalMenuFile = File(result.files.single.path!);
                            globalMenuIsPdf = result.files.single.extension?.toLowerCase() == 'pdf';
                          });
                          setState((){});
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: brandInputBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: brandOrange.withOpacity(0.5))
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.add_circle_outline, color: brandOrange, size: 48),
                            SizedBox(height: 8),
                            Text("Upload PDF or Image", style: TextStyle(color: brandGray, fontWeight: FontWeight.w500))
                          ]
                        )
                      )
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: brandInputBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(globalMenuIsPdf ? Icons.picture_as_pdf : Icons.image, color: brandOrange),
                          const SizedBox(width: 12),
                          Expanded(child: Text(globalMenuFile!.path.split(Platform.pathSeparator).last, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              setDialogState(() {
                                globalMenuFile = null;
                                globalMenuIsPdf = false;
                              });
                              setState((){});
                            },
                          )
                        ],
                      )
                    )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: brandGray))
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) {
            int unread = globalComplaints.where((c) => c.date.isAfter(globalAdminLastViewedComplaints) && !globalAdminHiddenComplaints.contains(c.id)).length;
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
              accountName: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: const Text("Administrator"),
              currentAccountPicture: CircleAvatar(
                backgroundImage: FileImage(widget.photo),
              ),
            ),
            ExpansionTile(
              leading: const Icon(Icons.restaurant, color: brandDark),
              title: const Text('Mess Entry', style: TextStyle(fontWeight: FontWeight.w600)),
              children: [
                SwitchListTile(
                  title: const Text('Breakfast'),
                  activeColor: brandOrange,
                  value: globalEntryB,
                  onChanged: (v) => setState(() => globalEntryB = v),
                ),
                SwitchListTile(
                  title: const Text('Lunch'),
                  activeColor: brandOrange,
                  value: globalEntryL,
                  onChanged: (v) => setState(() => globalEntryL = v),
                ),
                SwitchListTile(
                  title: const Text('Dinner'),
                  activeColor: brandOrange,
                  value: globalEntryD,
                  onChanged: (v) => setState(() => globalEntryD = v),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.poll, color: brandDark),
              title: const Text('Mess Poll', style: TextStyle(fontWeight: FontWeight.w600)),
              children: [
                SwitchListTile(
                  title: const Text('Breakfast'),
                  activeColor: brandOrange,
                  value: globalPollB,
                  onChanged: (v) => setState(() => globalPollB = v),
                ),
                SwitchListTile(
                  title: const Text('Lunch'),
                  activeColor: brandOrange,
                  value: globalPollL,
                  onChanged: (v) => setState(() => globalPollL = v),
                ),
                SwitchListTile(
                  title: const Text('Dinner'),
                  activeColor: brandOrange,
                  value: globalPollD,
                  onChanged: (v) => setState(() => globalPollD = v),
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.fact_check, color: brandDark),
              title: const Text('Attendance Sheet', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: brandDark),
              title: const Text('View All Register Student', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRegisteredStudentsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.set_meal, color: brandDark),
              title: const Text('Set Menu', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _showSetMenuDialog();
              },
            ),
            Builder(
              builder: (context) {
                int unread = globalComplaints.where((c) => c.date.isAfter(globalAdminLastViewedComplaints) && !globalAdminHiddenComplaints.contains(c.id)).length;
                return ListTile(
                  leading: const Icon(Icons.report_problem_outlined, color: brandDark),
                  title: Row(
                    children: [
                      const Text('View Student Complaints', style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        )
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() { globalAdminLastViewedComplaints = DateTime.now(); });
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AdminComplaintsScreen(
                      hidden: globalAdminHiddenComplaints,
                      onDelete: (id) => setState(() => globalAdminHiddenComplaints.add(id)),
                    ))).then((_) => setState((){}));
                  },
                );
              }
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('LogOut', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
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
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 36, backgroundImage: FileImage(widget.photo)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Admin Portal", style: TextStyle(color: brandGray, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(widget.name, style: const TextStyle(color: brandDark, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    : const ViewMenuTab(),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: brandOrange,
        unselectedItemColor: brandGray,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notice"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: "Menu"),
        ],
      ),
    );
  }
}

class StudentComplaintsScreen extends StatefulWidget {
  final String name;
  final String roomNo;
  final File photo;
  const StudentComplaintsScreen({super.key, required this.name, required this.roomNo, required this.photo});
  @override
  State<StudentComplaintsScreen> createState() => _StudentComplaintsScreenState();
}
class _StudentComplaintsScreenState extends State<StudentComplaintsScreen> {
  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("New Complaint", style: TextStyle(color: brandDark, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: InputDecoration(labelText: "Title", filled: true, fillColor: brandInputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            TextField(controller: msgCtrl, maxLines: 4, decoration: InputDecoration(labelText: "Description", filled: true, fillColor: brandInputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: brandGray))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                setState(() {
                  globalComplaints.insert(0, ComplaintItem(DateTime.now().toString(), titleCtrl.text, msgCtrl.text, DateTime.now(), widget.name, widget.roomNo, widget.photo));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          )
        ]
      )
    );
  }
  @override
  Widget build(BuildContext context) {
    final myComplaints = globalComplaints.where((c) => c.studentName == widget.name && !globalStudentHiddenComplaints.contains(c.id)).toList();
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(title: const Text("Mess Complaints"), backgroundColor: brandOrange, foregroundColor: Colors.white),
      body: myComplaints.isEmpty ? const Center(child: Text("No complaints yet.", style: TextStyle(color: brandGray))) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myComplaints.length,
        itemBuilder: (context, index) {
          final c = myComplaints[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4), Text(c.description, style: const TextStyle(color: brandGray)), const SizedBox(height: 8),
                Text(formatDateTime(c.date), style: const TextStyle(fontSize: 11, color: brandOrange, fontWeight: FontWeight.w600))
              ]),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => setState(() => globalStudentHiddenComplaints.add(c.id)),
              )
            )
          );
        }
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, backgroundColor: brandOrange, child: const Icon(Icons.add, color: Colors.white)),
    );
  }
}

class AdminComplaintsScreen extends StatefulWidget {
  final Set<String> hidden;
  final Function(String) onDelete;
  const AdminComplaintsScreen({super.key, required this.hidden, required this.onDelete});
  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}
class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  @override
  Widget build(BuildContext context) {
    final visible = globalComplaints.where((c) => !widget.hidden.contains(c.id)).toList();
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(title: const Text("Student Complaints"), backgroundColor: brandOrange, foregroundColor: Colors.white),
      body: visible.isEmpty ? const Center(child: Text("No complaints yet.", style: TextStyle(color: brandGray))) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final c = visible[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(backgroundImage: FileImage(c.studentPhoto)),
              title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4), Text(c.description, style: const TextStyle(color: brandDark)),
                const SizedBox(height: 6), Text("By: ${c.studentName} (Room ${c.studentRoom})", style: const TextStyle(color: brandGray, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4), Text(formatDateTime(c.date), style: const TextStyle(fontSize: 11, color: brandOrange, fontWeight: FontWeight.w600))
              ]),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () { widget.onDelete(c.id); setState((){}); },
              )
            )
          );
        }
      )
    );
  }
}

class AdminRegisteredStudentsScreen extends StatelessWidget {
  const AdminRegisteredStudentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(title: const Text("Registered Students"), backgroundColor: brandOrange, foregroundColor: Colors.white),
      body: globalRegisteredStudents.isEmpty ? const Center(child: Text("No students registered yet.", style: TextStyle(color: brandGray))) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: globalRegisteredStudents.length,
        itemBuilder: (context, index) {
          final s = globalRegisteredStudents[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(backgroundImage: FileImage(s.photo), radius: 24),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
              subtitle: Text("Room: ${s.roomNo}", style: const TextStyle(color: brandGray)),
            )
          );
        }
      )
    );
  }
}

class SwipeToConfirm extends StatefulWidget {
  final VoidCallback onConfirm;
  final String text;
  const SwipeToConfirm({super.key, required this.onConfirm, required this.text});

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  final double _height = 60.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
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
            Center(child: Text(widget.text, style: const TextStyle(fontWeight: FontWeight.w600, color: brandGray))),
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
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class MealPassScreen extends StatefulWidget {
  final String mealName;
  final File photo;
  final String name;
  final String roomNo;
  const MealPassScreen({super.key, required this.mealName, required this.photo, required this.name, required this.roomNo});
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
      setState(() { _now = DateTime.now(); });
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
         leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 100),
            const SizedBox(height: 16),
            Text("${widget.mealName.toUpperCase()} APPROVED", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: CircleAvatar(radius: 60, backgroundImage: FileImage(widget.photo)),
            ),
            const SizedBox(height: 16),
            Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text("Room: ${widget.roomNo}", style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(30)),
              child: Text(_formatTime(_now), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
            )
          ]
        )
      )
    );
  }
}

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});
  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  DateTime _selectedDailyDate = DateTime.now();
  String _dailySearchQuery = "";
  
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _monthlySearchQuery = "";
  String _paymentFilter = "All"; // All, Paid, Unpaid, Half Paid

  int _getDaysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

  // ===== DAILY VIEW LOGIC =====
  List<Map<String, dynamic>> _generateDailyRows() {
    List<Map<String, dynamic>> rows = [];
    String dateStr = "${_selectedDailyDate.year}-${_selectedDailyDate.month}-${_selectedDailyDate.day}";
    for (int roomInt = 101; roomInt <= 120; roomInt++) { _addDailyRoomSlots(rows, roomInt.toString(), dateStr); }
    for (int roomInt = 201; roomInt <= 220; roomInt++) { _addDailyRoomSlots(rows, roomInt.toString(), dateStr); }
    if (_dailySearchQuery.isNotEmpty) {
      String q = _dailySearchQuery.toLowerCase();
      rows = rows.where((r) => r['room'].toLowerCase().contains(q) || r['name'].toLowerCase().contains(q)).toList();
    }
    return rows;
  }

  void _addDailyRoomSlots(List<Map<String, dynamic>> rows, String room, String dateStr) {
    var roomStudents = globalRegisteredStudents.where((s) => s.roomNo == room).toList();
    for (int i = 0; i < 4; i++) {
      if (i < roomStudents.length) {
        String name = roomStudents[i].name;
        String key = "${dateStr}_${room}_$name";
        DailyRecord? rec = globalAttendanceMap[key];
        int total = 0;
        if (rec != null) {
          if (rec.b == 'P') total += 20;
          if (rec.l == 'P') total += 60;
          if (rec.d == 'P') total += 60;
        }
        rows.add({
          'room': room,
          'name': name,
          'isEmpty': false,
          'hasAttendance': rec != null,
          'b': rec?.b ?? '-',
          'l': rec?.l ?? '-',
          'd': rec?.d ?? '-',
          'total': total,
        });
      } else {
        rows.add({'room': room, 'name': 'Empty Slot', 'isEmpty': true, 'hasAttendance': false, 'b': '-', 'l': '-', 'd': '-', 'total': 0});
      }
    }
  }

  Widget _buildDailyView() {
    final rows = _generateDailyRows();
    String dateStr = "${_selectedDailyDate.day.toString().padLeft(2,'0')}/${_selectedDailyDate.month.toString().padLeft(2,'0')}/${_selectedDailyDate.year}";
    
    return Column(
      children: [
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _dailySearchQuery = val),
                )
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDailyDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _selectedDailyDate = picked);
                },
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                label: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: brandDark, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )
            ]
          )
        ),
        Container(
          color: brandDark,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text("Room", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text("Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text("B", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text("L", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text("D", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ]
          )
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              Color bgColor = index % 2 == 0 ? Colors.white : Colors.grey.shade50;
              bool showDivider = (index + 1) % 4 == 0;
              
              Widget buildCell(String text) {
                Color textColor = brandGray;
                if (text == 'P') textColor = Colors.green;
                else if (text == 'A') textColor = Colors.redAccent;
                return Text(text, style: TextStyle(color: textColor, fontWeight: text == 'P' || text == 'A' ? FontWeight.bold : FontWeight.w500));
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: showDivider ? const Border(bottom: BorderSide(color: Colors.black12, width: 2)) : null
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(row['room'], style: TextStyle(fontWeight: FontWeight.bold, color: row['isEmpty'] ? Colors.grey : brandDark))),
                    Expanded(flex: 3, child: Text(row['name'], style: TextStyle(color: row['isEmpty'] ? Colors.grey : brandDark, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 1, child: buildCell(row['b'])),
                    Expanded(flex: 1, child: buildCell(row['l'])),
                    Expanded(flex: 1, child: buildCell(row['d'])),
                    Expanded(flex: 2, child: Text(row['hasAttendance'] ? dateStr : '', style: const TextStyle(color: brandGray, fontSize: 11, fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text(row['hasAttendance'] ? "₹${row['total']}" : (row['isEmpty'] ? '' : '-'), textAlign: TextAlign.right, style: TextStyle(color: row['total'] > 0 ? brandOrange : brandGray, fontWeight: FontWeight.bold))),
                  ]
                )
              );
            }
          )
        )
      ]
    );
  }

  // ===== MONTHLY VIEW LOGIC =====
  List<Map<String, dynamic>> _generateMonthlyRows() {
    List<Map<String, dynamic>> rows = [];
    int daysInMonth = _getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    
    for(var student in globalRegisteredStudents) {
      String monthKey = "${_selectedMonth.year}-${_selectedMonth.month}_${student.roomNo}_${student.name}";

      int present = 0;
      int absent = 0;
      int actual = 0;

      for(int d=1; d<=daysInMonth; d++) {
         String dayKey = "${_selectedMonth.year}-${_selectedMonth.month}-${d}_${student.roomNo}_${student.name}";
         var rec = globalAttendanceMap[dayKey];
         if(rec != null) {
            bool isP = rec.b == 'P' || rec.l == 'P' || rec.d == 'P';
            if(isP) present++; else absent++;
            if(rec.b == 'P') actual += 20;
            if(rec.l == 'P') actual += 60;
            if(rec.d == 'P') actual += 60;
         }
      }
      
      int payable = 0;
      if (present == 0 && absent == 0) { payable = 0; }
      else if (present <= 22) { payable = 3080; }
      else { payable = actual; }

      int paidAmt = globalMonthlyPaid[monthKey] ?? 0;
      String pStatus = 'Paid';
      if (payable == 0) pStatus = 'Paid';
      else if (paidAmt == 0) pStatus = 'Unpaid';
      else if (paidAmt < payable) pStatus = 'Half Paid';

      if (_paymentFilter != 'All' && _paymentFilter != pStatus) continue;

      if (_monthlySearchQuery.isNotEmpty) {
        String q = _monthlySearchQuery.toLowerCase();
        if (!student.roomNo.toLowerCase().contains(q) && !student.name.toLowerCase().contains(q)) continue;
      }

      rows.add({
         'paid': paidAmt,
         'student': student,
         'present': present,
         'absent': absent,
         'actual': actual,
         'payable': payable,
         'status': pStatus,
         'monthKey': monthKey
      });
    }
    
    // Sort by Room No
    rows.sort((a, b) => (a['student'] as RegisteredStudent).roomNo.compareTo((b['student'] as RegisteredStudent).roomNo));
    return rows;
  }

  void _showStudentHistoryDialog(RegisteredStudent student, Map<String, dynamic> rowData) {
    int daysInMonth = _getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    List<Map<String, dynamic>> history = [];
    
    for(int d=1; d<=daysInMonth; d++) {
       String dayKey = "${_selectedMonth.year}-${_selectedMonth.month}-${d}_${student.roomNo}_${student.name}";
       var rec = globalAttendanceMap[dayKey];
       if(rec != null) {
          int dailyTotal = 0;
          if(rec.b == 'P') dailyTotal += 20;
          if(rec.l == 'P') dailyTotal += 60;
          if(rec.d == 'P') dailyTotal += 60;
          history.add({
             'day': d,
             'b': rec.b,
             'l': rec.l,
             'd': rec.d,
             'total': dailyTotal
          });
       }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))
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
                          Text("${student.name} (Room ${student.roomNo})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text("Month: ${_selectedMonth.month}/${_selectedMonth.year} | Payable: ₹${rowData['payable']}", style: const TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                        ]
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                  ]
                )
              ),
              Container(
                color: brandDark,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text("Date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text("B", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text("L", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text("D", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ]
                )
              ),
              Expanded(
                child: history.isEmpty 
                  ? const Center(child: Text("No attendance records found for this month."))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, idx) {
                        var h = history[idx];
                        Widget buildCell(String text) {
                          Color c = brandGray;
                          if (text == 'P') c = Colors.green;
                          if (text == 'A') c = Colors.redAccent;
                          return Text(text, style: TextStyle(color: c, fontWeight: FontWeight.bold));
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text("${h['day'].toString().padLeft(2,'0')}/${_selectedMonth.month.toString().padLeft(2,'0')}")),
                              Expanded(flex: 1, child: buildCell(h['b'])),
                              Expanded(flex: 1, child: buildCell(h['l'])),
                              Expanded(flex: 1, child: buildCell(h['d'])),
                              Expanded(flex: 2, child: Text("₹${h['total']}", textAlign: TextAlign.right, style: const TextStyle(color: brandDark, fontWeight: FontWeight.bold))),
                            ]
                          )
                        );
                      }
                    )
              )
            ]
          )
        );
      }
    );
  }

  Widget _buildMonthlyView() {
    final rows = _generateMonthlyRows();
    List<String> monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String monthStr = "${monthNames[_selectedMonth.month]} ${_selectedMonth.year}";
    
    return Column(
      children: [
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setState(() => _monthlySearchQuery = val),
                    )
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: brandInputBg, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _paymentFilter,
                          items: ['All', 'Paid', 'Half Paid', 'Unpaid'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
                          onChanged: (val) => setState(() => _paymentFilter = val!),
                        )
                      )
                    )
                  ),
                ]
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: brandDark),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.month == 1 ? _selectedMonth.year - 1 : _selectedMonth.year,
                          _selectedMonth.month == 1 ? 12 : _selectedMonth.month - 1
                        );
                      });
                    }
                  ),
                  Text(monthStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: brandDark),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.month == 12 ? _selectedMonth.year + 1 : _selectedMonth.year,
                          _selectedMonth.month == 12 ? 1 : _selectedMonth.month + 1
                        );
                      });
                    }
                  ),
                ]
              )
            ]
          )
        ),
        Container(
          color: brandDark,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text("Student", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 1, child: Text("P", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 1, child: Text("A", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text("Bill", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 3, child: Text("Status", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
            ]
          )
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              RegisteredStudent student = row['student'];
              Color bgColor = index % 2 == 0 ? Colors.white : Colors.grey.shade50;
              
              Color statusColor = Colors.redAccent;
              if (row['status'] == 'Paid') statusColor = Colors.green;
              if (row['status'] == 'Half Paid') statusColor = Colors.orange;

              return InkWell(
                onTap: () => _showStudentHistoryDialog(student, row),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: const Border(bottom: BorderSide(color: Colors.black12))
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3, 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text("Rm: ${student.roomNo}", style: const TextStyle(color: brandGray, fontSize: 11)),
                          ]
                        )
                      ),
                      Expanded(flex: 1, child: Text("${row['present']}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text("${row['absent']}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text("₹${row['payable']}", textAlign: TextAlign.center, style: const TextStyle(color: brandOrange, fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(
                        flex: 3, 
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              TextEditingController amtCtrl = TextEditingController(text: row['paid'].toString());
                              showDialog(context: context, builder: (ctx) {
                                return AlertDialog(
                                  title: const Text("Update Payment"),
                                  content: TextField(
                                    controller: amtCtrl, 
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: "Paid Amount (₹)", filled: true, fillColor: brandInputBg, border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)))
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          globalMonthlyPaid[row['monthKey']] = int.tryParse(amtCtrl.text) ?? 0;
                                        });
                                        Navigator.pop(ctx);
                                      }, 
                                      style: ElevatedButton.styleFrom(backgroundColor: brandDark),
                                      child: const Text("Save", style: TextStyle(color: Colors.white))
                                    )
                                  ]
                                );
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              decoration: BoxDecoration(color: brandInputBg, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                "₹${row['paid']}",
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                              )
                            )
                          )
                        )
                      ),
                    ]
                  )
                )
              );
            }
          )
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: brandBg,
        appBar: AppBar(
          backgroundColor: brandOrange,
          title: const Text("Attendance Sheet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Daily View"),
              Tab(text: "Monthly View"),
            ]
          ),
        ),
        body: TabBarView(
          children: [
            _buildDailyView(),
            _buildMonthlyView(),
          ]
        )
      )
    );
  }
}

class StudentAttendanceScreen extends StatefulWidget {
  final String name;
  final String roomNo;
  const StudentAttendanceScreen({super.key, required this.name, required this.roomNo});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    String suffix = "_${widget.roomNo}_${widget.name}";
    List<String> myKeys = globalAttendanceMap.keys.where((k) => k.endsWith(suffix)).toList();
    
    List<Map<String, dynamic>> records = [];
    for (String key in myKeys) {
      String datePart = key.split('_')[0];
      List<String> parts = datePart.split('-');
      int y = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      int d = int.parse(parts[2]);
      DateTime dt = DateTime(y, m, d);
      
      if (selectedDate != null) {
        if (dt.year != selectedDate!.year || dt.month != selectedDate!.month || dt.day != selectedDate!.day) {
          continue;
        }
      }
      
      DailyRecord rec = globalAttendanceMap[key]!;
      int total = 0;
      if (rec.b == 'P') total += 20;
      if (rec.l == 'P') total += 60;
      if (rec.d == 'P') total += 60;
      
      records.add({
        'dateObj': dt,
        'dateStr': "${d.toString().padLeft(2,'0')}/${m.toString().padLeft(2,'0')}/$y",
        'b': rec.b,
        'l': rec.l,
        'd': rec.d,
        'total': total
      });
    }
    
    records.sort((a, b) => (b['dateObj'] as DateTime).compareTo(a['dateObj'] as DateTime));

    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: const Text("My Attendance", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => selectedDate = null)
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context, 
                initialDate: selectedDate ?? DateTime.now(), 
                firstDate: DateTime(2020), 
                lastDate: DateTime(2030)
              );
              if (picked != null) setState(() => selectedDate = picked);
            }
          )
        ]
      ),
      body: Column(
        children: [
          Container(
            color: brandDark,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("Room", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("B", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("L", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("D", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("Date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ]
            )
          ),
          if (records.isEmpty)
            const Expanded(child: Center(child: Text("No attendance records found.", style: TextStyle(color: brandGray))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final row = records[index];
                  Color bgColor = index % 2 == 0 ? Colors.white : Colors.grey.shade50;
                  
                  Widget buildCell(String text) {
                    Color textColor = brandGray;
                    if (text == 'P') textColor = Colors.green;
                    else if (text == 'A') textColor = Colors.redAccent;
                    return Text(text, style: TextStyle(color: textColor, fontWeight: text == 'P' || text == 'A' ? FontWeight.bold : FontWeight.w500));
                  }

                  return Container(
                    color: bgColor,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(widget.roomNo, style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark))),
                        Expanded(flex: 3, child: Text(widget.name, style: const TextStyle(color: brandDark, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Expanded(flex: 1, child: buildCell(row['b'])),
                        Expanded(flex: 1, child: buildCell(row['l'])),
                        Expanded(flex: 1, child: buildCell(row['d'])),
                        Expanded(flex: 3, child: Text(row['dateStr'], style: const TextStyle(color: brandGray, fontSize: 11, fontWeight: FontWeight.w600))),
                        Expanded(flex: 2, child: Text("₹${row['total']}", textAlign: TextAlign.right, style: TextStyle(color: row['total'] > 0 ? brandOrange : brandGray, fontWeight: FontWeight.bold))),
                      ]
                    )
                  );
                }
              )
            )
        ]
      )
    );
  }
}
