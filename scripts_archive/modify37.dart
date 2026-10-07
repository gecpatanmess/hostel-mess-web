import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // Add globalMonthlyPaid check in _buildAttendanceCard
  String calcTarget = '''
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
''';

  String calcReplacement = '''
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

    String monthKey = "\${currentYear}-\${currentMonth}\${suffix}";
    int paidAmt = globalMonthlyPaid[monthKey] ?? 0;
    int dueAmt = payableBill - paidAmt;
    if (dueAmt < 0) dueAmt = 0;
''';

  content = content.replaceFirst(calcTarget, calcReplacement);

  // Update the UI of the card to show Paid and Due
  String uiTarget = '''
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Payable Bill", style: TextStyle(color: brandGray, fontWeight: FontWeight.w600, fontSize: 13)),
                            Row(
                              children: [
                                Text("₹\$payableBill", style: const TextStyle(color: brandOrange, fontSize: 20, fontWeight: FontWeight.bold)),
                                if (minRuleApplied) 
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Text("(Min 22-day rule)", style: TextStyle(color: brandGray, fontSize: 10)),
                                  )
                              ]
                            )
                          ]
                        )
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Actual Bill", style: TextStyle(color: brandGray, fontWeight: FontWeight.w600, fontSize: 13)),
                            Text("₹\$actualBill", style: const TextStyle(color: brandDark, fontSize: 20, fontWeight: FontWeight.bold)),
                          ]
                        )
                      )
''';

  String uiReplacement = '''
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Payable Bill", style: TextStyle(color: brandGray, fontWeight: FontWeight.w600, fontSize: 12)),
                            Text("₹\$payableBill", style: const TextStyle(color: brandOrange, fontSize: 16, fontWeight: FontWeight.bold)),
                            if (minRuleApplied) 
                              const Text("(22-day rule)", style: TextStyle(color: brandGray, fontSize: 10))
                          ]
                        )
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text("Paid", style: TextStyle(color: brandGray, fontWeight: FontWeight.w600, fontSize: 12)),
                            Text("₹\$paidAmt", style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                          ]
                        )
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Due Amount", style: TextStyle(color: brandGray, fontWeight: FontWeight.w600, fontSize: 12)),
                            Text("₹\$dueAmt", style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                          ]
                        )
                      )
''';

  content = content.replaceFirst(uiTarget, uiReplacement);

  file.writeAsStringSync(content);
}
