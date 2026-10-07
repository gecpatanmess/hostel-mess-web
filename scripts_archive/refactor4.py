import os

filepath = 'lib/main.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    code = f.read()

while "UrlUrl" in code:
    code = code.replace("UrlUrl", "Url")

code = code.replace("                      child: (!kIsWeb && c.studentPhotoUrl != null && c.studentPhotoUrl!.existsSync()) ? null : const Icon(Icons.person, color: Colors.white),\n", "")
code = code.replace("                      child: (!kIsWeb && s.photoUrl != null && s.photoUrl!.existsSync()) ? null : const Icon(Icons.person, color: Colors.white),\n", "")
code = code.replace("                              child: (!kIsWeb && st.photoUrl != null && st.photoUrl!.existsSync()) ? null : const Icon(Icons.person, color: Colors.white, size: 20),\n", "")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(code)
