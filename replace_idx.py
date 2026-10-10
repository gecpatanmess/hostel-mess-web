import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_block = '''              if (student == null) {
                globalRegisteredStudents.add(
                  RegisteredStudent(
                    nameCtrl.text,
                    roomCtrl.text,
                    null,
                    '',
                    email: emailCtrl.text.trim(),
                  ),
                );
              } else {
                int idx = globalRegisteredStudents.indexOf(student);
                if (idx != -1) {
                  globalRegisteredStudents[idx] = RegisteredStudent(
                    nameCtrl.text,
                    roomCtrl.text,
                    student.photoUrl,
                    student.pin,
                    email: emailCtrl.text.trim(),
                  );
                }
              }
              await SyncService.updateStudentTargeted(globalRegisteredStudents[idx]);
              Navigator.pop(ctx);'''

new_block = '''              RegisteredStudent? targetStudent;
              if (student == null) {
                targetStudent = RegisteredStudent(
                  nameCtrl.text,
                  roomCtrl.text,
                  null,
                  '',
                  email: emailCtrl.text.trim(),
                );
                globalRegisteredStudents.add(targetStudent);
              } else {
                int foundIdx = globalRegisteredStudents.indexOf(student);
                if (foundIdx != -1) {
                  targetStudent = RegisteredStudent(
                    nameCtrl.text,
                    roomCtrl.text,
                    student.photoUrl,
                    student.pin,
                    email: emailCtrl.text.trim(),
                  );
                  globalRegisteredStudents[foundIdx] = targetStudent;
                }
              }
              if (targetStudent != null) {
                await SyncService.updateStudentTargeted(targetStudent);
              }
              if (ctx.mounted) Navigator.pop(ctx);'''

if old_block in content:
    content = content.replace(old_block, new_block)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed idx error")
else:
    print("Block not found")
