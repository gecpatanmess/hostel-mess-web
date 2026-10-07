with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old_logic = """    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        initialBreakfast = data['breakfast'] ?? initialBreakfast;
        initialLunch = data['lunch'] ?? initialLunch;
        initialDinner = data['dinner'] ?? initialDinner;
      }
    } catch(e) {}"""

new_logic = """    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        if (data['breakfast'] != null && data['breakfast'].toString().trim().isNotEmpty) initialBreakfast = data['breakfast'];
        if (data['lunch'] != null && data['lunch'].toString().trim().isNotEmpty) initialLunch = data['lunch'];
        if (data['dinner'] != null && data['dinner'].toString().trim().isNotEmpty) initialDinner = data['dinner'];
      }
    } catch(e) {}"""

if old_logic in code:
    code = code.replace(old_logic, new_logic)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Fixed _showSetMenuDialog logic!")
else:
    print("Could not find old logic in _showSetMenuDialog.")
