import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  // Replace the exact 3 instances
  content = content.replaceAll('''
                      setState(() {
                        if (mealType == 'L') {
                          rec.l = (rec.l == 'P') ? 'A' : 'P';
                        } else {
                          rec.d = (rec.d == 'P') ? 'A' : 'P';
                        }
                        globalAttendanceMap[key] = rec;
                        await SyncService.pushAttendance(key, rec);
                      });
''', '''
                      if (mealType == 'L') {
                        rec.l = (rec.l == 'P') ? 'A' : 'P';
                      } else {
                        rec.d = (rec.d == 'P') ? 'A' : 'P';
                      }
                      globalAttendanceMap[key] = rec;
                      await SyncService.pushAttendance(key, rec);
                      setState(() {});
''');

  content = content.replaceAll('''
                                      setState(() {
                                        if (mealType == 'L') {
                                          rec.l = (rec.l == 'P') ? 'A' : 'P';
                                        } else {
                                          rec.d = (rec.d == 'P') ? 'A' : 'P';
                                        }
                                        globalAttendanceMap[key] = rec;
                                        await SyncService.pushAttendance(key, rec);

                                        setState(
                                          () {},
                                        ); // trigger rebuild on parent for instant UI update
                                      });
''', '''
                                      if (mealType == 'L') {
                                        rec.l = (rec.l == 'P') ? 'A' : 'P';
                                      } else {
                                        rec.d = (rec.d == 'P') ? 'A' : 'P';
                                      }
                                        globalAttendanceMap[key] = rec;
                                        await SyncService.pushAttendance(key, rec);
                                        setState(() {});
''');

  content = content.replaceAll('''
                                setState(() {
                                  if (mealType == 'L') {
                                    rec.l = (rec.l == 'P') ? 'A' : 'P';
                                  } else {
                                    rec.d = (rec.d == 'P') ? 'A' : 'P';
                                  }
                                  globalAttendanceMap[key] = rec;
                                  await SyncService.pushAttendance(key, rec);
                                });
''', '''
                                  if (mealType == 'L') {
                                    rec.l = (rec.l == 'P') ? 'A' : 'P';
                                  } else {
                                    rec.d = (rec.d == 'P') ? 'A' : 'P';
                                  }
                                  globalAttendanceMap[key] = rec;
                                  await SyncService.pushAttendance(key, rec);
                                  setState((){});
''');

  file.writeAsStringSync(content);
}
