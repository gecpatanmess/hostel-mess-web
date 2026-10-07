with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old_logic = """        if (snapshot.hasData) {
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
        }"""

new_logic = """        if (snapshot.hasData) {
          // 1. Weekly template override
          final weekSnap = snapshot.data![0];
          if (weekSnap.exists && weekSnap.value != null) {
            final wData = Map<String, dynamic>.from(weekSnap.value as Map);
            if (wData['breakfast'] != null && wData['breakfast'].toString().trim().isNotEmpty) bf = wData['breakfast'];
            if (wData['lunch'] != null && wData['lunch'].toString().trim().isNotEmpty) lu = wData['lunch'];
            if (wData['dinner'] != null && wData['dinner'].toString().trim().isNotEmpty) dn = wData['dinner'];
          }
          // 2. Daily override
          final daySnap = snapshot.data![1];
          if (daySnap.exists && daySnap.value != null) {
            final dData = Map<String, dynamic>.from(daySnap.value as Map);
            if (dData['breakfast'] != null && dData['breakfast'].toString().trim().isNotEmpty) bf = dData['breakfast'];
            if (dData['lunch'] != null && dData['lunch'].toString().trim().isNotEmpty) lu = dData['lunch'];
            if (dData['dinner'] != null && dData['dinner'].toString().trim().isNotEmpty) dn = dData['dinner'];
          }
        }"""

if old_logic in code:
    code = code.replace(old_logic, new_logic)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Fixed ViewMenuTab logic!")
else:
    print("Could not find old logic in ViewMenuTab.")
