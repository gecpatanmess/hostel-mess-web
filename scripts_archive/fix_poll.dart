import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Fix Poll Reset in Admin Switch
  String adminPollL = '''SwitchListTile(
                    title: const Text('Lunch'),
                    activeColor: brandOrange,
                    value: globalPollL,
                    onChanged: (v) {
                      setState(() {
                        globalPollL = v;
                        if (v) {
                          String today = "\${DateTime.now().year}-\${DateTime.now().month}-\${DateTime.now().day}";
                          if (globalPollDate != today) {
                            globalPollDate = today;
                            todayPollVotes['L']?.clear();
                            todayPollVotes['D']?.clear();
                          }
                        }
                      });
                    },
                  ),''';
  content = content.replaceFirst('''SwitchListTile(
                    title: const Text('Lunch'),
                    activeColor: brandOrange,
                    value: globalPollL,
                    onChanged: (v) => setState(() => globalPollL = v),
                  ),''', adminPollL);

  String adminPollD = '''SwitchListTile(
                    title: const Text('Dinner'),
                    activeColor: brandOrange,
                    value: globalPollD,
                    onChanged: (v) {
                      setState(() {
                        globalPollD = v;
                        if (v) {
                          String today = "\${DateTime.now().year}-\${DateTime.now().month}-\${DateTime.now().day}";
                          if (globalPollDate != today) {
                            globalPollDate = today;
                            todayPollVotes['L']?.clear();
                            todayPollVotes['D']?.clear();
                          }
                        }
                      });
                    },
                  ),''';
  content = content.replaceFirst('''SwitchListTile(
                    title: const Text('Dinner'),
                    activeColor: brandOrange,
                    value: globalPollD,
                    onChanged: (v) => setState(() => globalPollD = v),
                  ),''', adminPollD);

  file.writeAsStringSync(content);
}
