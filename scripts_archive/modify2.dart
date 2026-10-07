import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // Remove Breakfast switch list tiles
  content = content.replaceAll(
'''                SwitchListTile(
                  title: const Text('Breakfast'),
                  activeColor: brandOrange,
                  value: globalEntryB,
                  onChanged: (v) => setState(() => globalEntryB = v),
                ),''', 
'''                // removed Breakfast switch'''
  );

  content = content.replaceAll(
'''                SwitchListTile(
                  title: const Text('Breakfast'),
                  activeColor: brandOrange,
                  value: globalPollB,
                  onChanged: (v) => setState(() => globalPollB = v),
                ),''', 
'''                // removed Breakfast poll switch'''
  );

  // Remove Breakfast Live Poll
  content = content.replaceAll(
'''                      Column(children: [const Icon(Icons.free_breakfast, color: brandOrange), const SizedBox(height: 4), Text("\${todayPollVotes['B']!.length}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Text("Breakfast", style: TextStyle(color: brandGray, fontSize: 12))]),''',
''''''
  );

  // activeMeal logic
  content = content.replaceAll(
'''    String activeMeal = '';
    if (globalEntryB) activeMeal = 'Breakfast';
    else if (globalEntryL) activeMeal = 'Lunch';
    else if (globalEntryD) activeMeal = 'Dinner';''',
'''    String activeMeal = '';
    if (globalEntryL) activeMeal = 'Lunch';
    else if (globalEntryD) activeMeal = 'Dinner';'''
  );

  content = content.replaceAll("if (activeMeal == 'Breakfast' && todayRecord.b.isNotEmpty) { hasAction = true; statusStr = todayRecord.b; }", "");
  content = content.replaceAll("if (activeMeal == 'Breakfast') globalAttendanceMap[key]!.b = 'P';\n                              else ", "");
  content = content.replaceAll("if (activeMeal == 'Breakfast') globalAttendanceMap[key]!.b = 'A';\n                              else ", "");

  // Poll Check B logic
  content = content.replaceAll("bool _pollCheckB = false;", "");
  content = content.replaceAll("if (globalPollB) _buildPollOption(\"Breakfast\", canVoteB, _pollCheckB, (v) => setState(() => _pollCheckB = v!)),", "");
  content = content.replaceAll("bool votedB = todayPollVotes['B']!.contains(studentKey);", "");
  content = content.replaceAll("bool canVoteB = globalPollB && !votedB;", "");
  content = content.replaceAll("bool hasPendingVote = canVoteB || canVoteL || canVoteD;", "bool hasPendingVote = canVoteL || canVoteD;");
  content = content.replaceAll("if (!_pollCheckB && !_pollCheckL && !_pollCheckD)", "if (!_pollCheckL && !_pollCheckD)");
  content = content.replaceAll("if (_pollCheckB) todayPollVotes['B']!.add(studentKey);", "");
  content = content.replaceAll("_pollCheckB = false; _pollCheckL = false; _pollCheckD = false;", "_pollCheckL = false; _pollCheckD = false;");
  content = content.replaceAll("if (!globalPollB && !globalPollL && !globalPollD)", "if (!globalPollL && !globalPollD)");

  // Payment UI (Student Dashboard)
  String paymentAddition = '''
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
                        const Text("Paid Amount", style: TextStyle(color: brandDark, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("₹\$paidAmt", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
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
                        const Text("Pending/Due", style: TextStyle(color: brandDark, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("₹\$dueAmt", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ]
                    )
                  )
                ),
              ]
            ),
''';
  content = content.replaceAll(
    "const SizedBox(height: 16),\n            \n            SizedBox(\n              width: double.infinity,\n              child: OutlinedButton.icon(",
    paymentAddition + "            const SizedBox(height: 16),\n            \n            SizedBox(\n              width: double.infinity,\n              child: OutlinedButton.icon("
  );

  // Admin Monthly View Headers
  content = content.replaceAll(
'''              Expanded(flex: 3, child: Text("Student", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 1, child: Text("P", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 1, child: Text("A", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text("Bill", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 3, child: Text("Status", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),''',
'''              Expanded(flex: 3, child: Text("Student", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 1, child: Text("P", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 1, child: Text("A", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text("Bill", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text("Paid", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text("Due", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),'''
  );

  // Admin Monthly View Row
  content = content.replaceAll(
'''                      Expanded(
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
                      ),''',
'''                      Expanded(
                        flex: 2, 
                        child: Align(
                          alignment: Alignment.center,
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
                      Expanded(flex: 2, child: Text("₹\${(row['payable'] - row['paid'] < 0) ? 0 : row['payable'] - row['paid']}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13))),'''
  );

  // Removing 'B' columns in attendance screens
  content = content.replaceAll('Expanded(flex: 1, child: Text("B", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),', '');
  content = content.replaceAll("Expanded(flex: 1, child: buildCell(row['b'])),", "");
  content = content.replaceAll("Expanded(flex: 1, child: buildCell(h['b'])),", "");
  content = content.replaceAll("'b': rec?.b ?? '-',", "");
  content = content.replaceAll("'b': rec.b,", "");
  
  file.writeAsStringSync(content);
}
