import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Inject the StudentAttendanceScreen class at the end
  String newScreen = '''
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
    String suffix = "_\${widget.roomNo}_\${widget.name}";
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
        'dateStr': "\${d.toString().padLeft(2,'0')}/\${m.toString().padLeft(2,'0')}/\$y",
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
                        Expanded(flex: 2, child: Text("₹\${row['total']}", textAlign: TextAlign.right, style: TextStyle(color: row['total'] > 0 ? brandOrange : brandGray, fontWeight: FontWeight.bold))),
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

  if (!content.contains('class StudentAttendanceScreen')) {
    content = content + '\n' + newScreen;
  }

  // 2. Update Student Drawer Tile
  String oldTile = '''            ListTile(
              leading: const Icon(Icons.co_present, color: brandDark),
              title: const Text('My Attendance', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () { Navigator.pop(context); },
            ),''';
  
  String newTile = '''            ListTile(
              leading: const Icon(Icons.co_present, color: brandDark),
              title: const Text('My Attendance', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => StudentAttendanceScreen(name: widget.name, roomNo: widget.roomNo)));
              },
            ),''';

  content = content.replaceFirst(oldTile, newTile);
  
  file.writeAsStringSync(content);
}
