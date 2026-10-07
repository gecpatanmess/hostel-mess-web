import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String text = file.readAsStringSync();
  
  // 1. _buildDailyView
  int idx = text.indexOf('Widget _buildDailyView() {');
  if (idx != -1) {
    int idxContainer = text.indexOf('Container(', text.indexOf('return Column(', idx));
    if (idxContainer != -1) {
      String insert = """
    void export(String format) {
        List<String> h = ["Room", "Student Name", "Lunch", "Dinner", "Total"];
        List<List<String>> d = _generateDailyRows().map((r) => [
           r['room'].toString(), r['name'].toString(), r['l'].toString(), r['d'].toString(), r['total'].toString()
        ]).toList();
        String dateStr = "\${_selectedDailyDate.day}-\${_selectedDailyDate.month}-\${_selectedDailyDate.year}";
        ExportService.exportReport(context: context, title: "Daily Attendance - \$dateStr", headers: h, data: d, format: format);
    }
    
    """;
      text = text.substring(0, text.indexOf('return Column(', idx)) + insert + "return Column(\n      children: [\n        _buildExportRow(onExcel: () => export('excel'), onPdf: () => export('pdf'), onImage: () => export('image')),\n        " + text.substring(idxContainer);
    }
  }

  // 2. _buildMonthlyView
  int idx2 = text.indexOf('Widget _buildMonthlyView() {');
  if (idx2 != -1) {
    int idxContainer = text.indexOf('Container(', text.indexOf('return Column(', idx2));
    if (idxContainer != -1) {
      String insert = """
    void export(String format) {
        List<String> h = ["Room", "Student Name", "P", "A", "Actual", "Payable", "Paid", "Due"];
        List<List<String>> d = _generateMonthlyRows().map((r) => [
           r['room'].toString(), r['name'].toString(), r['present'].toString(), r['absent'].toString(),
           r['actual'].toString(), r['payable'].toString(), r['paid'].toString(),
           (r['payable'] - r['paid']).toString()
        ]).toList();
        List<String> monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        String monthStr = "\${monthNames[_selectedMonth.month]} \${_selectedMonth.year}";
        ExportService.exportReport(context: context, title: "Monthly Attendance - \$monthStr", headers: h, data: d, format: format);
    }
    
    """;
      text = text.substring(0, text.indexOf('return Column(', idx2)) + insert + "return Column(\n      children: [\n        _buildExportRow(onExcel: () => export('excel'), onPdf: () => export('pdf'), onImage: () => export('image')),\n        " + text.substring(idxContainer);
    }
  }

  // 3. Student bottom sheet
  String searchStr = '''
                        )
                  )
                ]
              )
            );
// --- TEMPORARY EDITING BLOCK START ---
          }
        );''';
        
  String replacementStr = '''
                        )
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                       Column(
                         children: [
                           const Text("Export Month:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                           _buildExportRow(
                             onExcel: () {
                               List<String> h = ["Date", "Lunch", "Dinner", "Total"];
                               List<List<String>> d = history.map((hi) => [
                                 "\${hi['day']}/\${_selectedMonth.month}", hi['l'].toString(), hi['d'].toString(), hi['total'].toString()
                               ]).toList();
                               ExportService.exportReport(context: context, title: "\${student.name} - \${_selectedMonth.month}-\${_selectedMonth.year}", headers: h, data: d, format: 'excel');
                             },
                             onPdf: () {
                               List<String> h = ["Date", "Lunch", "Dinner", "Total"];
                               List<List<String>> d = history.map((hi) => [
                                 "\${hi['day']}/\${_selectedMonth.month}", hi['l'].toString(), hi['d'].toString(), hi['total'].toString()
                               ]).toList();
                               ExportService.exportReport(context: context, title: "\${student.name} - \${_selectedMonth.month}-\${_selectedMonth.year}", headers: h, data: d, format: 'pdf');
                             },
                             onImage: () {
                               List<String> h = ["Date", "Lunch", "Dinner", "Total"];
                               List<List<String>> d = history.map((hi) => [
                                 "\${hi['day']}/\${_selectedMonth.month}", hi['l'].toString(), hi['d'].toString(), hi['total'].toString()
                               ]).toList();
                               ExportService.exportReport(context: context, title: "\${student.name} - \${_selectedMonth.month}-\${_selectedMonth.year}", headers: h, data: d, format: 'image');
                             }
                           )
                         ]
                       ),
                       Column(
                         children: [
                           const Text("Export Year:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                           _buildExportRow(
                             onExcel: () {
                               List<String> h = ["Month", "Present", "Absent", "Actual", "Payable", "Paid", "Due"];
                               var yStats = _generateYearlyStats(student, _selectedMonth.year);
                               List<List<String>> d = yStats.map((y) => [
                                  y['month'].toString(), y['p'].toString(), y['a'].toString(), y['actual'].toString(),
                                  y['payable'].toString(), y['paid'].toString(), y['due'].toString()
                               ]).toList();
                               ExportService.exportReport(context: context, title: "\${student.name} - Yearly \${_selectedMonth.year}", headers: h, data: d, format: 'excel');
                             },
                             onPdf: () {
                               List<String> h = ["Month", "Present", "Absent", "Actual", "Payable", "Paid", "Due"];
                               var yStats = _generateYearlyStats(student, _selectedMonth.year);
                               List<List<String>> d = yStats.map((y) => [
                                  y['month'].toString(), y['p'].toString(), y['a'].toString(), y['actual'].toString(),
                                  y['payable'].toString(), y['paid'].toString(), y['due'].toString()
                               ]).toList();
                               ExportService.exportReport(context: context, title: "\${student.name} - Yearly \${_selectedMonth.year}", headers: h, data: d, format: 'pdf');
                             },
                             onImage: () {
                               List<String> h = ["Month", "Present", "Absent", "Actual", "Payable", "Paid", "Due"];
                               var yStats = _generateYearlyStats(student, _selectedMonth.year);
                               List<List<String>> d = yStats.map((y) => [
                                  y['month'].toString(), y['p'].toString(), y['a'].toString(), y['actual'].toString(),
                                  y['payable'].toString(), y['paid'].toString(), y['due'].toString()
                               ]).toList();
                               ExportService.exportReport(context: context, title: "\${student.name} - Yearly \${_selectedMonth.year}", headers: h, data: d, format: 'image');
                             }
                           )
                         ]
                       )
                    ]
                  ),
                  const SizedBox(height: 10),
                ]
              )
            );
// --- TEMPORARY EDITING BLOCK START ---
          }
        );''';
  if (text.contains(searchStr)) {
    text = text.replaceAll(searchStr, replacementStr);
    print("Replaced bottom sheet!");
  } else {
    print("Could not find bottom sheet search str");
  }

  file.writeAsStringSync(text);
  print("Patched completely!");
}
