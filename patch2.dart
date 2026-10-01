import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String text = file.readAsStringSync();
  
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
  
  // Note: the original file has '₹' in it, which might cause parsing differences if not careful.
  // But my search string is exactly the end structure.
  
  int idx = text.indexOf(searchStr);
  if (idx != -1) {
    text = text.substring(0, idx) + replacementStr + text.substring(idx + searchStr.length);
    file.writeAsStringSync(text);
    print("Patched bottom sheet!");
  } else {
    print("Could not find bottom sheet search str");
  }
}
