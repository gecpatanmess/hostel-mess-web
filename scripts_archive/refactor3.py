import re
import os

filepath = 'lib/main.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace("if (!kIsWeb && s.photo != null && s.photo!.existsSync()) {", "if (s.photoUrl != null && s.photoUrl!.isNotEmpty) {")
code = code.replace("photoBase64 = s.photo!.path;", "photoUrl = s.photoUrl ?? '';")

code = code.replace("s.photo", "s.photoUrl")
code = code.replace("st.photo", "st.photoUrl")
code = code.replace("existingStudent.photo", "existingStudent.photoUrl")
code = code.replace("c.studentPhoto", "c.studentPhotoUrl")
code = code.replace("studentPhoto", "studentPhotoUrl")
code = code.replace("adminPhoto", "adminPhotoUrl")

# Revert wrongly substituted photoUrlUrl if any (due to cascading replaces)
code = code.replace("photoUrlUrl", "photoUrl")

code = code.replace("child: (!kIsWeb && s.photoUrl != null && s.photoUrl!.existsSync()) ? null : const Icon(Icons.person, color: Colors.white),", "")
code = code.replace("child: (!kIsWeb && c.studentPhotoUrl != null && c.studentPhotoUrl!.existsSync()) ? null : const Icon(Icons.person, color: Colors.white),", "")
code = code.replace("child: (!kIsWeb && st.photoUrl != null && st.photoUrl!.existsSync()) ? null : const Icon(Icons.person, color: Colors.white, size: 20),", "")

code = code.replace("(!kIsWeb && (existingStudent.photoUrl == null || !existingStudent.photoUrl!.existsSync() || existingStudent.photoUrl!.path.contains('dummy')))", "(existingStudent.photoUrl == null || existingStudent.photoUrl!.isEmpty)")

code = code.replace("(kIsWeb || studentPhotoUrl == null || !studentPhotoUrl!.existsSync())", "(studentPhotoUrl == null || studentPhotoUrl!.isEmpty)")
code = code.replace("(kIsWeb || adminPhotoUrl == null || !adminPhotoUrl!.existsSync())", "(adminPhotoUrl == null || adminPhotoUrl!.isEmpty)")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(code)
