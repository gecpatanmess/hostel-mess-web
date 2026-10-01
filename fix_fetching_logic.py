import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix ViewMenuTab fetching
# In ViewMenuTab:
# future: FirebaseDatabase.instance.ref('hostelData/daily_menus/').get(),
# Change to a custom future

view_menu_fetch = '''    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance.ref('hostelData/daily_menus/').get(),
      builder: (context, snapshot) {
        String bf = defaultMenu['breakfast']!;
        String lu = defaultMenu['lunch']!;
        String dn = defaultMenu['dinner']!;
        if (snapshot.hasData && snapshot.data!.value != null) {
          final data = Map<String, dynamic>.from(snapshot.data!.value as Map);
          bf = data['breakfast'] ?? bf;
          lu = data['lunch'] ?? lu;
          dn = data['dinner'] ?? dn;
        }'''

view_menu_replace = '''    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final weekDay = now.weekday;

    return FutureBuilder<List<DataSnapshot>>(
      future: Future.wait([
        FirebaseDatabase.instance.ref('hostelData/weekly_template/$weekDay').get(),
        FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').get(),
      ]),
      builder: (context, snapshot) {
        String bf = defaultMenu['breakfast']!;
        String lu = defaultMenu['lunch']!;
        String dn = defaultMenu['dinner']!;
        
        if (snapshot.hasData) {
          // 1. Weekly template override
          final weekSnap = snapshot.data![0];
          if (weekSnap.exists && weekSnap.value != null) {
            final wData = Map<String, dynamic>.from(weekSnap.value as Map);
            bf = wData['breakfast'] ?? bf;
            lu = wData['lunch'] ?? lu;
            dn = wData['dinner'] ?? dn;
          }
          // 2. Daily override
          final daySnap = snapshot.data![1];
          if (daySnap.exists && daySnap.value != null) {
            final dData = Map<String, dynamic>.from(daySnap.value as Map);
            bf = dData['breakfast'] ?? bf;
            lu = dData['lunch'] ?? lu;
            dn = dData['dinner'] ?? dn;
          }
        }'''

code = code.replace(view_menu_fetch, view_menu_replace)

# Fix Admin Set Menu Dialog fetching
# In _showSetMenuDialog
admin_fetch = '''      try {
        final snap = await FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').get();
        if (snap.exists && snap.value != null) {
          final data = Map<String, dynamic>.from(snap.value as Map);
          initialBreakfast = data['breakfast'] ?? initialBreakfast;
          initialLunch = data['lunch'] ?? initialLunch;
          initialDinner = data['dinner'] ?? initialDinner;
        }
      } catch(e) {}'''

admin_replace = '''      try {
        final weekSnap = await FirebaseDatabase.instance.ref('hostelData/weekly_template/$weekDay').get();
        if (weekSnap.exists && weekSnap.value != null) {
          final wData = Map<String, dynamic>.from(weekSnap.value as Map);
          initialBreakfast = wData['breakfast'] ?? initialBreakfast;
          initialLunch = wData['lunch'] ?? initialLunch;
          initialDinner = wData['dinner'] ?? initialDinner;
        }
        
        final snap = await FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').get();
        if (snap.exists && snap.value != null) {
          final data = Map<String, dynamic>.from(snap.value as Map);
          initialBreakfast = data['breakfast'] ?? initialBreakfast;
          initialLunch = data['lunch'] ?? initialLunch;
          initialDinner = data['dinner'] ?? initialDinner;
        }
      } catch(e) {}'''

code = code.replace(admin_fetch, admin_replace)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Fetching logic updated!")
