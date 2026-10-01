import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // Find the exact line in _buildAttendanceCard
  String target = '''            Row(
              children: [
                Expanded(child: _buildStatBox("Payable Bill", "₹\$payableBill", brandOrange, subtext: "(Min 22-day rule)")),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox("Actual Bill", "₹\$actualBill", brandDark, subtext: "(Real cost)")),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(''';

  // Make sure we calculate paid and due amounts properly.
  // We need to inject the calculation above this target or just do it inline inside the replacement.
  String calculation = '''
    String paymentKey = "\$currentYear-\${currentMonth}_\${widget.roomNo}_\${widget.name}";
    int paidAmount = globalMonthlyPaid[paymentKey] ?? 0;
    int dueAmount = payableBill - paidAmount;
    if (dueAmount < 0) dueAmount = 0;
''';

  String replacement = '''            Row(
              children: [
                Expanded(child: _buildStatBox("Payable Bill", "₹\$payableBill", brandOrange, subtext: "(Min 22-day rule)")),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox("Actual Bill", "₹\$actualBill", brandDark, subtext: "(Real cost)")),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatBox("Paid", "₹\$paidAmount", Colors.green, subtext: "(Amount Paid)")),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox("Due (Pending)", "₹\$dueAmount", Colors.redAccent, subtext: "(To be paid)")),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(''';

  // We need to inject `calculation` before `String monthName = `
  String calcTarget = '''    String monthName = [''';
  content = content.replaceFirst(calcTarget, calculation + "\n" + calcTarget);
  content = content.replaceFirst(target, replacement);

  file.writeAsStringSync(content);
}
