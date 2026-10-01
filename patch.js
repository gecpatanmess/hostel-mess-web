
const fs = require("fs");
let content = fs.readFileSync("lib/main.dart", "utf-8");
let index = content.indexOf("Widget _buildMonthlyView() {");
if (index !== -1) {
    let before = content.substring(0, index);
    let after = content.substring(index);
    let patch = `                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            "Export Year:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          _buildExportRow(
                            onExcel: () {
                              List<String> h = [
                                "Month",
                                "Present",
                                "Absent",
                                "Actual",
                                "Payable",
                                "Paid",
                                "Due",
                              ];
                              List<List<String>> d = [];
                              for (int m = 1; m <= 12; m++) {
                                String key = "${_selectedMonth.year}-${m}_${student.roomNo}_${student.name}";
                                int paid = globalMonthlyPaid[key] ?? 0;
                                int p = 0;
                                int a = 0;
                                for (int day = 1; day <= 31; day++) {
                                  String dKey = "${_selectedMonth.year}-${m}-${day}_${student.roomNo}_${student.name}";
                                  if (globalAttendanceMap.containsKey(dKey)) {
                                    if (globalAttendanceMap[dKey]!.l == "P") p++;
                                    else if (globalAttendanceMap[dKey]!.l == "A") a++;
                                    if (globalAttendanceMap[dKey]!.d == "P") p++;
                                    else if (globalAttendanceMap[dKey]!.d == "A") a++;
                                  }
                                }
                                int actual = p * 70;
                                int payable = (p == 0 && a == 0) ? 0 : (actual > 3080 ? actual : 3080);
                                int due = payable - paid;
                                if (p > 0 || a > 0 || paid > 0) {
                                  d.push([m.toString(), p.toString(), a.toString(), actual.toString(), payable.toString(), paid.toString(), due.toString()]);
                                }
                              }
                              ExportService.exportReport(
                                context: context,
                                title: "${student.name} - Yearly ${_selectedMonth.year}",
                                headers: h,
                                data: d,
                                format: "excel",
                              );
                            },
                            onPdf: () {
                              // Similar to excel
                              List<String> h = [
                                "Month",
                                "Present",
                                "Absent",
                                "Actual",
                                "Payable",
                                "Paid",
                                "Due",
                              ];
                              List<List<String>> d = [];
                              // I will implement Dart code here
                              ExportService.exportReport(
                                context: context,
                                title: "${student.name} - Yearly ${_selectedMonth.year}",
                                headers: h,
                                data: d,
                                format: "pdf",
                              );
                            }
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  `;
  // I will just use dart code instead of pseudo code
}

