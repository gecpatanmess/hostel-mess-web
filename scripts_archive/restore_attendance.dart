import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  String attendanceCode = '''
  Widget _buildStatBox(String title, String value, Color color, {String? subtext}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          if (subtext != null)
            Text(subtext, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    String suffix = "_\${widget.roomNo}_\${widget.name}";
    int currentMonth = _attendanceMonth.month;
    int currentYear = _attendanceMonth.year;

    int presentDays = 0;
    int absentDays = 0;
    int actualBill = 0;

    globalAttendanceMap.forEach((key, rec) {
      if (!key.endsWith(suffix)) return;
      String datePart = key.split('_')[0];
      List<String> parts = datePart.split('-');
      if (parts.length != 3) return;
      int y = int.tryParse(parts[0]) ?? 0;
      int m = int.tryParse(parts[1]) ?? 0;
      if (y != currentYear || m != currentMonth) return;

      bool dayPresent = (rec.l == 'P' || rec.d == 'P');
      if (dayPresent) {
        presentDays++;
      } else {
        absentDays++;
      }

      if (rec.l == 'P') actualBill += 70;
      if (rec.d == 'P') actualBill += 70;
    });

    int payableBill = 0;
    if (presentDays > 0 || absentDays > 0) {
      payableBill = math.max(actualBill, 3080);
    }

    String monthName = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ][currentMonth];

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: brandOrange),
                    SizedBox(width: 8),
                    Text("Attendance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16, color: brandOrange),
                      onPressed: () => setState(() {
                        _attendanceMonth = DateTime(_attendanceMonth.year, _attendanceMonth.month - 1, 1);
                      }),
                    ),
                    Text("\$monthName \$currentYear", style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16, color: brandOrange),
                      onPressed: () => setState(() {
                        _attendanceMonth = DateTime(_attendanceMonth.year, _attendanceMonth.month + 1, 1);
                      }),
                    ),
                  ],
                )
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: _buildStatBox("Present", "\$presentDays Days", Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox("Absent", "\$absentDays Days", Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatBox("Payable Bill", "₹\$payableBill", brandOrange, subtext: "(Min 22-day rule)")),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox("Actual Bill", "₹\$actualBill", brandDark, subtext: "(Real cost)")),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentAttendanceScreen(name: widget.name, roomNo: widget.roomNo)));
                },
                icon: const Icon(Icons.list_alt, color: Colors.white),
                label: const Text("View Full Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          ],
        ),
      )
    );
  }

  Widget _buildPollCard() {''';

  content = content.replaceAll("  Widget _buildPollCard() {", attendanceCode);
  
  content = content.replaceAll("_buildPollCard(),\n      ],", "_buildPollCard(),\n        _buildAttendanceCard(),\n      ],");

  file.writeAsStringSync(content);
}
