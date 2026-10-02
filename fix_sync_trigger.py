with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix 1: WeeklyMenuEditorWidget
old_weekly = """      await FirebaseDatabase.instance.ref('hostelData/weekly_template/$_selectedDay').set({
        'breakfast': _bfCtrl.text.trim(),
        'lunch': _luCtrl.text.trim(),
        'dinner': _dnCtrl.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Menu for day $_selectedDay updated!"), backgroundColor: Colors.green));"""

new_weekly = """      await FirebaseDatabase.instance.ref('hostelData/weekly_template/$_selectedDay').set({
        'breakfast': _bfCtrl.text.trim(),
        'lunch': _luCtrl.text.trim(),
        'dinner': _dnCtrl.text.trim(),
      });
      globalSyncTrigger.notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Menu for day $_selectedDay updated!"), backgroundColor: Colors.green));"""

code = code.replace(old_weekly, new_weekly)

# Fix 2: _showSetMenuDialog
old_daily = """                    await FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').set({
                      'breakfast': bfCtrl.text.trim(),
                      'lunch': luCtrl.text.trim(),
                      'dinner': dnCtrl.text.trim(),
                    });
                    if (mounted) {"""

new_daily = """                    await FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').set({
                      'breakfast': bfCtrl.text.trim(),
                      'lunch': luCtrl.text.trim(),
                      'dinner': dnCtrl.text.trim(),
                    });
                    globalSyncTrigger.notifyListeners();
                    if (mounted) {"""

code = code.replace(old_daily, new_daily)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Injected globalSyncTrigger.notifyListeners()!")
