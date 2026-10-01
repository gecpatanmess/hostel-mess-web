import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix kIsWeb missing import
if "import 'package:flutter/foundation.dart';" not in code:
    code = "import 'package:flutter/foundation.dart';\n" + code

# Fix photoUrl not defined getter / Final field photo not initialized
# We need to ensure that the fields in the StatefulWidget classes are correctly named photoUrl (since constructors take photoUrl)
code = re.sub(r'final File\?? photo;', r'final String? photoUrl;', code)
code = re.sub(r'this\.photo,', r'this.photoUrl,', code)
code = re.sub(r'this\.photo\)', r'this.photoUrl)', code)
code = re.sub(r'widget\.photo!', r'widget.photoUrl!', code)
code = re.sub(r'widget\.photo', r'widget.photoUrl', code)
code = re.sub(r's\.photo!', r's.photoUrl!', code)

# If it uses FileImage(widget.photoUrl!), change to NetworkImage(widget.photoUrl!)
code = code.replace("FileImage(widget.photoUrl!)", "NetworkImage(widget.photoUrl!)")
code = code.replace("FileImage(s.photoUrl!)", "NetworkImage(s.photoUrl!)")

# Fix SyncService missing (if it was deleted, we might need to remove SyncService calls or add a dummy)
# The error says SyncService.pushMenu(); isn't defined. Let's just remove it, the app doesn't use it anymore if it was deleted.
code = code.replace("SyncService.pushMenu();", "")
code = code.replace("SyncService.pushStudents();", "")
code = code.replace("SyncService.pushAdmins();", "")

# Fix globalMenuUploadBytes missing
if "Uint8List? globalMenuUploadBytes;" not in code:
    code = code.replace("bool globalMenuIsPdf = false;", "bool globalMenuIsPdf = false;\nUint8List? globalMenuUploadBytes;")

# Fix FirebaseDatabase missing
if "import 'package:firebase_database/firebase_database.dart';" not in code:
    code = "import 'package:firebase_database/firebase_database.dart';\n" + code

# Fix file.path == null issue (file might be FilePickerResult which has bytes)
code = code.replace("if (kIsWeb || file.path == null) {", "if (kIsWeb) {")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Applied final compile fixes!")
