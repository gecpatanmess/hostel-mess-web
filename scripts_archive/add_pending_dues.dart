import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  // 1. Add _getPendingDues method
  String pendingDuesLogic = '''
  List<Map<String, dynamic>> _getPendingDues() {
    List<Map<String, dynamic>> pendingList = [];
    DateTime now = DateTime.now();
    int prevMonth = now.month == 1 ? 12 : now.month - 1;
    int prevYear = now.month == 1 ? now.year - 1 : now.year;
    String monthKeyPrefix = "\$prevYear-\$prevMonth";
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String monthName = months[prevMonth - 1];

    for (var student in globalRegisteredStudents) {
      String pKey = "\${student.roomNo}_\${student.name}";
      
      int presentCount = 0;
      int absentCount = 0;
      int daysInMonth = 31;
      try {
        daysInMonth = DateTime(prevYear, prevMonth + 1, 0).day;
      } catch (e) {}

      for (int d = 1; d <= daysInMonth; d++) {
        String dailyKey = "\${monthKeyPrefix}_\${d}_\$pKey";
        if (globalAttendanceMap.containsKey(dailyKey)) {
          var rec = globalAttendanceMap[dailyKey]!;
          if (rec.l == 'P') presentCount++;
          if (rec.l == 'A') absentCount++;
          if (rec.d == 'P') presentCount++;
          if (rec.d == 'A') absentCount++;
        }
      }

      if (presentCount == 0 && absentCount == 0) continue; 

      int actualBill = presentCount * 70;
      int payableBill = math.max(actualBill, 3080);
      
      String monthPaidKey = "\${monthKeyPrefix}_\$pKey";
      int paidAmt = globalMonthlyPaid[monthPaidKey] ?? 0;

      if (paidAmt < payableBill) {
        pendingList.add({
          'student': student,
          'monthName': monthName,
          'year': prevYear,
          'payable': payableBill,
          'paid': paidAmt,
          'due': payableBill - paidAmt,
        });
      }
    }
    return pendingList;
  }
''';

  content = content.replaceFirst(
    'class _AdminDashboardScreenState extends State<AdminDashboardScreen> {',
    'class _AdminDashboardScreenState extends State<AdminDashboardScreen> {\n' + pendingDuesLogic
  );

  // 2. Add UI block to _buildAdminHomeTab
  String oldEnd = '''
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
''';
  
  String newEnd = '''
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...(() {
          var dues = _getPendingDues();
          if (dues.isEmpty) return [const SizedBox.shrink()];
          return [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                "⚠️ Pending Dues (Previous Month)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ),
            ...dues.map((due) {
              RegisteredStudent st = due['student'];
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: brandOrange,
                        backgroundImage: st.photo.existsSync() ? FileImage(st.photo) : null,
                        radius: 24,
                        child: st.photo.existsSync() ? null : const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "\${st.name} (Room \${st.roomNo})",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "\${due['monthName']} \${due['year']} - Bill: ₹\${due['payable']} | Paid: ₹\${due['paid']}",
                              style: const TextStyle(color: brandGray, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Pending Due: ₹\${due['due']}",
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ];
        })(),
      ],
    );
  }
''';

  content = content.replaceFirst(oldEnd.trim(), newEnd.trim());

  File('lib/main.dart').writeAsStringSync(content);
}
