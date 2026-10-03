import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  // Replace: setState(() { ... await ... }); with { ... } await ... setState(() {});
  content = content.replaceAll(
    "setState(() {\n                        if (mealType == 'L') {\n                          rec.l = (rec.l == 'P') ? 'A' : 'P';\n                        } else {\n                          rec.d = (rec.d == 'P') ? 'A' : 'P';\n                        }\n                        globalAttendanceMap[key] = rec;\n                        await SyncService.pushAttendance(key, rec);\n                      });",
    "if (mealType == 'L') {\n                          rec.l = (rec.l == 'P') ? 'A' : 'P';\n                        } else {\n                          rec.d = (rec.d == 'P') ? 'A' : 'P';\n                        }\n                        globalAttendanceMap[key] = rec;\n                        await SyncService.pushAttendance(key, rec);\n                        setState(() {});"
  );
  
  content = content.replaceAll(
    "setState(() {\n                                        if (mealType == 'L') {\n                                          rec.l = (rec.l == 'P') ? 'A' : 'P';\n                                        } else {\n                                          rec.d = (rec.d == 'P') ? 'A' : 'P';\n                                        }\n                                        globalAttendanceMap[key] = rec;\n                                        await SyncService.pushAttendance(key, rec);\n\n                                        setState(\n                                          () {},\n                                        ); // trigger rebuild on parent for instant UI update\n                                      });",
    "if (mealType == 'L') {\n                                          rec.l = (rec.l == 'P') ? 'A' : 'P';\n                                        } else {\n                                          rec.d = (rec.d == 'P') ? 'A' : 'P';\n                                        }\n                                        globalAttendanceMap[key] = rec;\n                                        await SyncService.pushAttendance(key, rec);\n\n                                        setState(() {});"
  );

  content = content.replaceAll(
    "setState(() {\n                                  if (mealType == 'L') {\n                                    rec.l = (rec.l == 'P') ? 'A' : 'P';\n                                  } else {\n                                    rec.d = (rec.d == 'P') ? 'A' : 'P';\n                                  }\n                                  globalAttendanceMap[key] = rec;\n                                  await SyncService.pushAttendance(key, rec);\n                                });",
    "if (mealType == 'L') {\n                                    rec.l = (rec.l == 'P') ? 'A' : 'P';\n                                  } else {\n                                    rec.d = (rec.d == 'P') ? 'A' : 'P';\n                                  }\n                                  globalAttendanceMap[key] = rec;\n                                  await SyncService.pushAttendance(key, rec);\n                                  setState(() {});"
  );

  file.writeAsStringSync(content);
}
