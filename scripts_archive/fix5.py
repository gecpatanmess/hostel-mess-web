with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old_block = """                    ] else ...[
                      Text(
                        hasSavedStudent ? "Room: ${savedStudentRoom ?? 'Unknown'}" : "",
                        style: const TextStyle(fontSize: 14, color: brandGray),
                      ),
                      Text(
                        hasSavedStudent ? (savedStudentName ?? "Student") : (_matchedStudent?.name ?? selectedStudentName ?? "Student"),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark),
                      ),
                    ],"""

new_block = """                    ] else ...[
                      Text(
                        hasSavedStudent ? "Room: ${savedStudentRoom ?? 'Unknown'}" : (_matchedStudent?.roomNo != null ? "Room: ${_matchedStudent!.roomNo}" : ""),
                        style: const TextStyle(fontSize: 14, color: brandGray),
                      ),
                      Text(
                        hasSavedStudent ? (savedStudentName ?? "Student") : (_matchedStudent?.name ?? selectedStudentName ?? "Student"),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark),
                      ),
                    ],"""

code = code.replace(old_block, new_block)

old_title = """              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Hostel Mess Management","""

new_title = """              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  (_authStage != AuthStage.identifier || hasSavedStudent || hasSavedAdmin) 
                      ? "${globalHostelMode == 'boys' ? 'Boys' : 'Girls'} Hostel Mess" 
                      : "Hostel Mess Management","""

code = code.replace(old_title, new_title)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print('Login UI UI fixes applied')
