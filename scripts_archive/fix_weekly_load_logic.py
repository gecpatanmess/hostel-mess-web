with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old_logic = """    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData/weekly_template/$_selectedDay').get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        bf = data['breakfast'] ?? bf;
        lu = data['lunch'] ?? lu;
        dn = data['dinner'] ?? dn;
      }
    } catch(e) {}"""

new_logic = """    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData/weekly_template/$_selectedDay').get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        if (data['breakfast'] != null && data['breakfast'].toString().trim().isNotEmpty) bf = data['breakfast'];
        if (data['lunch'] != null && data['lunch'].toString().trim().isNotEmpty) lu = data['lunch'];
        if (data['dinner'] != null && data['dinner'].toString().trim().isNotEmpty) dn = data['dinner'];
      }
    } catch(e) {}"""

if old_logic in code:
    code = code.replace(old_logic, new_logic)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Fixed _loadDayMenu logic!")
else:
    print("Could not find old logic in _loadDayMenu.")
