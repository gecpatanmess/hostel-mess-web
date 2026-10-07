import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // =========================================================================
  // FIX 1: Add pushSwitchesNow() method + _switchCooldown flag to SyncService
  // =========================================================================
  String oldSyncClass = '''class SyncService {
    static final _dbRef = FirebaseDatabase.instance.ref('hostelData');
    static bool _isSyncingIn = false;
    static bool _hasDownloadedOnce = false;
    static int _lastHash = 0;
    static String _lastMenuPath = "";
    static String _lastDownloadedMenuBase64 = "";''';

  String newSyncClass = '''class SyncService {
    static final _dbRef = FirebaseDatabase.instance.ref('hostelData');
    static bool _isSyncingIn = false;
    static bool _hasDownloadedOnce = false;
    static int _lastHash = 0;
    static String _lastMenuPath = "";
    static String _lastDownloadedMenuBase64 = "";
    static bool _switchCooldown = false;

    /// Immediately push ONLY the switches node to Firebase.
    /// Sets a cooldown so listen() won't overwrite for 3 seconds.
    static Future<void> pushSwitchesNow() async {
      _switchCooldown = true;
      try {
        await _dbRef.child('switches').set({
          'globalEntryL': globalEntryL,
          'globalEntryD': globalEntryD,
          'globalPollL': globalPollL,
          'globalPollD': globalPollD,
          'globalPollDate': globalPollDate,
        });
      } catch(e) {
        print("Push switches error: \$e");
      }
      // Keep cooldown for 3 seconds to let Firebase round-trip complete
      Future.delayed(const Duration(seconds: 3), () {
        _switchCooldown = false;
      });
    }''';

  content = content.replaceFirst(oldSyncClass, newSyncClass);

  // =========================================================================
  // FIX 2: In listen(), skip overwriting switches if _switchCooldown is true
  // =========================================================================
  String oldSwitchListen = '''        if (data['switches'] != null) {
          globalEntryL = data['switches']['globalEntryL'] ?? false;
          globalEntryD = data['switches']['globalEntryD'] ?? false;
          globalPollL = data['switches']['globalPollL'] ?? false;
          globalPollD = data['switches']['globalPollD'] ?? false;''';

  String newSwitchListen = '''        if (data['switches'] != null && !_switchCooldown) {
          globalEntryL = data['switches']['globalEntryL'] ?? false;
          globalEntryD = data['switches']['globalEntryD'] ?? false;
          globalPollL = data['switches']['globalPollL'] ?? false;
          globalPollD = data['switches']['globalPollD'] ?? false;''';

  content = content.replaceFirst(oldSwitchListen, newSwitchListen);

  // =========================================================================
  // FIX 3: Admin Mess Entry switches - call pushSwitchesNow() immediately
  // =========================================================================
  String oldEntryL = '''SwitchListTile(
                    title: const Text('Lunch'),
                    activeColor: brandOrange,
                    value: globalEntryL,
                    onChanged: (v) {
                      setState(() => globalEntryL = v);
                      if (v == false) {
                        _closeMessAndMarkAbsent('l');
                      }
                    },
                  ),''';

  String newEntryL = '''SwitchListTile(
                    title: const Text('Lunch'),
                    activeColor: brandOrange,
                    value: globalEntryL,
                    onChanged: (v) {
                      setState(() => globalEntryL = v);
                      SyncService.pushSwitchesNow();
                      if (v == false) {
                        _closeMessAndMarkAbsent('l');
                      }
                    },
                  ),''';

  content = content.replaceFirst(oldEntryL, newEntryL);

  String oldEntryD = '''SwitchListTile(
                    title: const Text('Dinner'),
                    activeColor: brandOrange,
                    value: globalEntryD,
                    onChanged: (v) {
                      setState(() => globalEntryD = v);
                      if (v == false) {
                        _closeMessAndMarkAbsent('d');
                      }
                    },
                  ),''';

  String newEntryD = '''SwitchListTile(
                    title: const Text('Dinner'),
                    activeColor: brandOrange,
                    value: globalEntryD,
                    onChanged: (v) {
                      setState(() => globalEntryD = v);
                      SyncService.pushSwitchesNow();
                      if (v == false) {
                        _closeMessAndMarkAbsent('d');
                      }
                    },
                  ),''';

  content = content.replaceFirst(oldEntryD, newEntryD);

  // =========================================================================
  // FIX 4: Admin Mess Poll switches - call pushSwitchesNow() immediately
  // =========================================================================
  // Find the poll Lunch switch (already updated with date reset logic)
  String oldPollLSwitch = '''onChanged: (v) {
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
                    },''';

  String newPollLSwitch = '''onChanged: (v) {
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
                      SyncService.pushSwitchesNow();
                    },''';

  content = content.replaceFirst(oldPollLSwitch, newPollLSwitch);

  String oldPollDSwitch = '''onChanged: (v) {
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
                    },''';

  String newPollDSwitch = '''onChanged: (v) {
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
                      SyncService.pushSwitchesNow();
                    },''';

  content = content.replaceFirst(oldPollDSwitch, newPollDSwitch);

  file.writeAsStringSync(content);
  print("SUCCESS: All switch fixes applied!");
}
