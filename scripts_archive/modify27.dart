import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Add month tracking state variable
  String oldState = '''class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;
  bool _pollCheckB = false;
  bool _pollCheckL = false;
  bool _pollCheckD = false;''';

  String newState = '''class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;
  bool _pollCheckB = false;
  bool _pollCheckL = false;
  bool _pollCheckD = false;
  DateTime _attendanceMonth = DateTime(DateTime.now().year, DateTime.now().month);''';

  content = content.replaceFirst(oldState, newState);

  // 2. Add _buildAttendanceCard() call in _buildHomeTab after _buildPollCard()
  String oldPollCall = '''        _buildPollCard()
      ],
    );
  }''';

  String newPollCall = '''        _buildPollCard(),
        _buildAttendanceCard()
      ],
    );
  }''';

  content = content.replaceFirst(oldPollCall, newPollCall);

  // 3. Insert _buildAttendanceCard() method before _buildPollOption
  String attendanceCardMethod = '''  Widget _buildAttendanceCard() {
    int currentMonth = _attendanceMonth.month;
    int currentYear = _attendanceMonth.year;
    String suffix = "_\${widget.roomNo}_\${widget.name}";
    
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
                  "\${monthNames[currentMonth]} \$currentYear",
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
                        Text("\$presentDays", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
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
                        Text("\$absentDays", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)),
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
                        Text("₹\$payableBill", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandOrange)),
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
                        Text("₹\$actualBill", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
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

''';

  String insertBefore = '  Widget _buildPollOption(';
  content = content.replaceFirst(insertBefore, attendanceCardMethod + insertBefore);

  file.writeAsStringSync(content);
}
