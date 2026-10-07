import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Globals replacement
  String newGlobals = '''
class DailyRecord {
  String b = ''; // P or A
  String l = '';
  String d = '';
}
Map<String, DailyRecord> globalAttendanceMap = {};
''';
  content = content.replaceFirst('Set<String> globalSwipedStudents = {};', newGlobals);

  // 2. Student Dashboard Home Tab update
  int homeStart = content.indexOf('  Widget _buildHomeTab() {');
  int noticeStart = content.indexOf('  Widget _buildNoticeTab() {');
  
  if (homeStart != -1 && noticeStart != -1) {
    String newHomeTab = '''  Widget _buildHomeTab() {
    String activeMeal = '';
    if (globalEntryB) activeMeal = 'Breakfast';
    else if (globalEntryL) activeMeal = 'Lunch';
    else if (globalEntryD) activeMeal = 'Dinner';

    DateTime now = DateTime.now();
    String key = "\${now.year}-\${now.month}-\${now.day}_\${widget.roomNo}_\${widget.name}";
    DailyRecord todayRecord = globalAttendanceMap[key] ?? DailyRecord();

    bool hasAction = false;
    String statusStr = "";
    if (activeMeal == 'Breakfast' && todayRecord.b.isNotEmpty) { hasAction = true; statusStr = todayRecord.b; }
    if (activeMeal == 'Lunch' && todayRecord.l.isNotEmpty) { hasAction = true; statusStr = todayRecord.l; }
    if (activeMeal == 'Dinner' && todayRecord.d.isNotEmpty) { hasAction = true; statusStr = todayRecord.d; }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
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
                        child: Text("\${DateTime.now().day.toString().padLeft(2, '0')}/\${DateTime.now().month.toString().padLeft(2, '0')}/\${DateTime.now().year}", style: const TextStyle(color: brandOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                      )
                    ]
                  ),
                  const Divider(height: 32),
                  if (activeMeal.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text("Mess is currently closed.\\nPlease wait for the next meal to start.", textAlign: TextAlign.center, style: TextStyle(color: brandGray, fontSize: 16)),
                      ),
                    )
                  else ...[
                    Center(child: Text("🍽️ \$activeMeal Time is Active", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
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
                            text: "Swipe for \$activeMeal",
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
          )
        ],
      ),
    );
  }

''';
    content = content.replaceRange(homeStart, noticeStart, newHomeTab);
  }

  // 3. Admin Drawer Route
  String oldAdminAtt = '''            ListTile(
              leading: const Icon(Icons.fact_check, color: brandDark),
              title: const Text('Attendance Sheet', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); },
            ),''';
  String newAdminAtt = '''            ListTile(
              leading: const Icon(Icons.fact_check, color: brandDark),
              title: const Text('Attendance Sheet', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()));
              },
            ),''';
  content = content.replaceFirst(oldAdminAtt, newAdminAtt);

  // 4. Append AdminAttendanceScreen
  String adminScreen = '''
class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});
  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';

  List<Map<String, dynamic>> _generateRows() {
    List<Map<String, dynamic>> rows = [];
    List<String> rooms = [];
    for (int i = 101; i <= 120; i++) rooms.add(i.toString());
    for (int i = 201; i <= 220; i++) rooms.add(i.toString());

    for (String room in rooms) {
      List<RegisteredStudent> roomStudents = globalRegisteredStudents.where((s) => s.roomNo == room).toList();
      for (int slot = 0; slot < 4; slot++) {
        RegisteredStudent? student;
        if (slot < roomStudents.length) {
          student = roomStudents[slot];
        }
        
        bool match = true;
        if (searchQuery.isNotEmpty) {
          String q = searchQuery.toLowerCase();
          bool roomMatch = room.toLowerCase().contains(q);
          bool nameMatch = student != null && student.name.toLowerCase().contains(q);
          if (!roomMatch && !nameMatch) match = false;
        }

        if (match) {
          String b = ''; String l = ''; String d = '';
          int total = 0;
          String nameToDisplay = student?.name ?? '—';

          if (student != null) {
            String key = "\${selectedDate.year}-\${selectedDate.month}-\${selectedDate.day}_\${room}_\${student.name}";
            DailyRecord? record = globalAttendanceMap[key];
            if (record != null) {
              b = record.b; l = record.l; d = record.d;
              if (b == 'P') total += 20;
              if (l == 'P') total += 60;
              if (d == 'P') total += 60;
            }
          }

          rows.add({
            'room': room,
            'name': nameToDisplay,
            'b': b, 'l': l, 'd': d,
            'total': total,
            'isEmpty': student == null
          });
        }
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _generateRows();
    
    return Scaffold(
      backgroundColor: brandBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: const Text("Attendance Sheet", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context, 
                initialDate: selectedDate, 
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Room No or Name",
                prefixIcon: const Icon(Icons.search, color: brandOrange),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
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
                if (row['isEmpty']) bgColor = Colors.grey.shade200;
                
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
                      Expanded(flex: 2, child: Text(row['room'], style: TextStyle(fontWeight: row['isEmpty'] ? FontWeight.normal : FontWeight.bold, color: row['isEmpty'] ? Colors.grey : brandDark))),
                      Expanded(flex: 3, child: Text(row['name'], style: TextStyle(color: row['isEmpty'] ? Colors.grey : brandDark, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 1, child: buildCell(row['b'])),
                      Expanded(flex: 1, child: buildCell(row['l'])),
                      Expanded(flex: 1, child: buildCell(row['d'])),
                      Expanded(flex: 2, child: Text("₹\${row['total']}", textAlign: TextAlign.right, style: TextStyle(color: row['isEmpty'] ? Colors.grey : (row['total'] > 0 ? brandOrange : brandGray), fontWeight: FontWeight.bold))),
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
''';

  if (!content.contains('class AdminAttendanceScreen')) {
    content = content + '\n' + adminScreen;
  }

  file.writeAsStringSync(content);
}
