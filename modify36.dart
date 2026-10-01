import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // Update _generateMonthlyRows logic in AdminAttendanceScreen
  String rowsLogicTarget = '''
    for(var student in globalRegisteredStudents) {
      String monthKey = "\${_selectedMonth.year}-\${_selectedMonth.month}_\${student.roomNo}_\${student.name}";
      String pStatus = globalPaymentStatus[monthKey] ?? 'Unpaid';
      
      if (_paymentFilter != 'All' && _paymentFilter != pStatus) continue;

      if (_monthlySearchQuery.isNotEmpty) {
''';

  String rowsLogicReplacement = '''
    for(var student in globalRegisteredStudents) {
      String monthKey = "\${_selectedMonth.year}-\${_selectedMonth.month}_\${student.roomNo}_\${student.name}";

      int present = 0;
      int absent = 0;
      int actual = 0;

      for(int d=1; d<=daysInMonth; d++) {
         String dayKey = "\${_selectedMonth.year}-\${_selectedMonth.month}-\${d}_\${student.roomNo}_\${student.name}";
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
''';

  content = content.replaceFirst(rowsLogicTarget, rowsLogicReplacement);

  // Remove the old loop for present/absent since we moved it above
  String oldLoopTarget = '''
      int present = 0;
      int absent = 0;
      int actual = 0;

      for(int d=1; d<=daysInMonth; d++) {
         String dayKey = "\${_selectedMonth.year}-\${_selectedMonth.month}-\${d}_\${student.roomNo}_\${student.name}";
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
''';
  
  String oldLoopReplacement = '''
      rows.add({
         'paid': paidAmt,
''';
  content = content.replaceFirst(oldLoopTarget, oldLoopReplacement);

  // Replace Payment Dropdown in UI
  String uiDropdownTarget = '''
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
''';

  String uiDropdownReplacement = '''
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
                                "₹\${row['paid']}",
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                              )
                            )
                          )
                        )
                      ),
''';
  content = content.replaceFirst(uiDropdownTarget, uiDropdownReplacement);

  file.writeAsStringSync(content);
}
