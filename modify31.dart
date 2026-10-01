import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Inject globalPaymentStatus
  String oldGlobalMap = 'Map<String, DailyRecord> globalAttendanceMap = {};';
  String newGlobalMap = 'Map<String, DailyRecord> globalAttendanceMap = {};\nMap<String, String> globalPaymentStatus = {};';
  if (!content.contains('Map<String, String> globalPaymentStatus')) {
    content = content.replaceFirst(oldGlobalMap, newGlobalMap);
  }

  // 2. Replace AdminAttendanceScreen
  // Start: class AdminAttendanceScreen extends StatefulWidget {
  // End: class StudentAttendanceScreen extends StatefulWidget {
  
  int startIdx = content.indexOf('class AdminAttendanceScreen extends StatefulWidget {');
  int endIdx = content.indexOf('class StudentAttendanceScreen extends StatefulWidget {');
  
  if (startIdx == -1 || endIdx == -1) {
    print("Could not find bounds");
    return;
  }

  String newAdminScreen = '''class AdminAttendanceScreen extends StatefulWidget {
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
    String dateStr = "\${_selectedDailyDate.year}-\${_selectedDailyDate.month}-\${_selectedDailyDate.day}";
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
        String key = "\${dateStr}_\${room}_\$name";
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
    String dateStr = "\${_selectedDailyDate.day.toString().padLeft(2,'0')}/\${_selectedDailyDate.month.toString().padLeft(2,'0')}/\${_selectedDailyDate.year}";
    
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
                    Expanded(flex: 2, child: Text(row['hasAttendance'] ? "₹\${row['total']}" : (row['isEmpty'] ? '' : '-'), textAlign: TextAlign.right, style: TextStyle(color: row['total'] > 0 ? brandOrange : brandGray, fontWeight: FontWeight.bold))),
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
      String monthKey = "\${_selectedMonth.year}-\${_selectedMonth.month}_\${student.roomNo}_\${student.name}";
      String pStatus = globalPaymentStatus[monthKey] ?? 'Unpaid';
      
      if (_paymentFilter != 'All' && _paymentFilter != pStatus) continue;

      if (_monthlySearchQuery.isNotEmpty) {
        String q = _monthlySearchQuery.toLowerCase();
        if (!student.roomNo.toLowerCase().contains(q) && !student.name.toLowerCase().contains(q)) continue;
      }

      int present = 0;
      int absent = 0;
      int actual = 0;

      for(int d=1; d<=daysInMonth; d++) {
         String dayKey = "\${_selectedMonth.year}-\${_selectedMonth.month}-\$d_\${student.roomNo}_\${student.name}";
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

      rows.add({
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
       String dayKey = "\${_selectedMonth.year}-\${_selectedMonth.month}-\$d_\${student.roomNo}_\${student.name}";
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
                          Text("\${student.name} (Room \${student.roomNo})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text("Month: \${_selectedMonth.month}/\${_selectedMonth.year} | Payable: ₹\${rowData['payable']}", style: const TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
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
                              Expanded(flex: 2, child: Text("\${h['day'].toString().padLeft(2,'0')}/\${_selectedMonth.month.toString().padLeft(2,'0')}")),
                              Expanded(flex: 1, child: buildCell(h['b'])),
                              Expanded(flex: 1, child: buildCell(h['l'])),
                              Expanded(flex: 1, child: buildCell(h['d'])),
                              Expanded(flex: 2, child: Text("₹\${h['total']}", textAlign: TextAlign.right, style: const TextStyle(color: brandDark, fontWeight: FontWeight.bold))),
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
    String monthStr = "\${monthNames[_selectedMonth.month]} \${_selectedMonth.year}";
    
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
                            Text("Rm: \${student.roomNo}", style: const TextStyle(color: brandGray, fontSize: 11)),
                          ]
                        )
                      ),
                      Expanded(flex: 1, child: Text("\${row['present']}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text("\${row['absent']}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text("₹\${row['payable']}", textAlign: TextAlign.center, style: const TextStyle(color: brandOrange, fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(
                        flex: 3, 
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: row['status'],
                              icon: const Icon(Icons.arrow_drop_down, size: 16),
                              isExpanded: true,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                              items: ['Paid', 'Half Paid', 'Unpaid'].map((s) {
                                Color c = Colors.redAccent;
                                if (s == 'Paid') c = Colors.green;
                                if (s == 'Half Paid') c = Colors.orange;
                                return DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)));
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  globalPaymentStatus[row['monthKey']] = val!;
                                });
                              },
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

''';

  content = content.replaceRange(startIdx, endIdx, newAdminScreen);
  file.writeAsStringSync(content);
}
