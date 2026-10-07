import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace Lunch Block
lunch_pattern = re.compile(
    r"(if \(todayRecord\.l\.isNotEmpty && _lunchMsgVisible\)\s*Container\([\s\S]*?Text\(todayRecord\.l == 'P' \? \"Attendance marked! \(P\)\" : \"Meal Skipped \(A\)\", style: TextStyle\(color: todayRecord\.l == 'P' \? Colors\.green : Colors\.redAccent, fontWeight: FontWeight\.bold\)\),)(\s*],)(\s*\),\s*\)\s*else if \(todayRecord\.l\.isEmpty\))"
)

def lunch_repl(m):
    return (
        "if (todayRecord.l.isNotEmpty)\n"
        "                      Container(\n"
        "                        padding: const EdgeInsets.all(12),\n"
        "                        decoration: BoxDecoration(color: (todayRecord.l == 'P' ? Colors.green : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),\n"
        "                        child: Row(\n"
        "                          children: [\n"
        "                            Icon(todayRecord.l == 'P' ? Icons.check_circle : Icons.cancel, color: todayRecord.l == 'P' ? Colors.green : Colors.redAccent),\n"
        "                            const SizedBox(width: 8),\n"
        "                            Expanded(child: Text(todayRecord.l == 'P' ? \"Attendance marked! (P)\" : \"Meal Skipped (A)\", style: TextStyle(color: todayRecord.l == 'P' ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold))),\n"
        "                            if (todayRecord.l == 'A')\n"
        "                              TextButton(\n"
        "                                onPressed: () async {\n"
        "                                  setState(() { todayRecord.l = ''; });\n"
        "                                  await SyncService.pushAttendance(key, todayRecord);\n"
        "                                },\n"
        "                                child: const Text(\"Undo\", style: TextStyle(fontWeight: FontWeight.bold)),\n"
        "                              )\n"
        "                          ],\n"
        "                        ),\n"
        "                      )\n"
        "                    else if (todayRecord.l.isEmpty)"
    )

# Replace Dinner Block
dinner_pattern = re.compile(
    r"(if \(todayRecord\.d\.isNotEmpty && _dinnerMsgVisible\)\s*Container\([\s\S]*?Text\(todayRecord\.d == 'P' \? \"Attendance marked! \(P\)\" : \"Meal Skipped \(A\)\", style: TextStyle\(color: todayRecord\.d == 'P' \? Colors\.green : Colors\.redAccent, fontWeight: FontWeight\.bold\)\),)(\s*],)(\s*\),\s*\)\s*else if \(todayRecord\.d\.isEmpty\))"
)

def dinner_repl(m):
    return (
        "if (todayRecord.d.isNotEmpty)\n"
        "                      Container(\n"
        "                        padding: const EdgeInsets.all(12),\n"
        "                        decoration: BoxDecoration(color: (todayRecord.d == 'P' ? Colors.green : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),\n"
        "                        child: Row(\n"
        "                          children: [\n"
        "                            Icon(todayRecord.d == 'P' ? Icons.check_circle : Icons.cancel, color: todayRecord.d == 'P' ? Colors.green : Colors.redAccent),\n"
        "                            const SizedBox(width: 8),\n"
        "                            Expanded(child: Text(todayRecord.d == 'P' ? \"Attendance marked! (P)\" : \"Meal Skipped (A)\", style: TextStyle(color: todayRecord.d == 'P' ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold))),\n"
        "                            if (todayRecord.d == 'A')\n"
        "                              TextButton(\n"
        "                                onPressed: () async {\n"
        "                                  setState(() { todayRecord.d = ''; });\n"
        "                                  await SyncService.pushAttendance(key, todayRecord);\n"
        "                                },\n"
        "                                child: const Text(\"Undo\", style: TextStyle(fontWeight: FontWeight.bold)),\n"
        "                              )\n"
        "                          ],\n"
        "                        ),\n"
        "                      )\n"
        "                    else if (todayRecord.d.isEmpty)"
    )

new_code = lunch_pattern.sub(lunch_repl, code)
new_code = dinner_pattern.sub(dinner_repl, new_code)

if new_code != code:
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(new_code)
    print("Modifications applied.")
else:
    print("No changes made. Pattern not found.")
