import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix kIsWeb missing import
if "import 'package:flutter/foundation.dart';" not in code:
    code = "import 'package:flutter/foundation.dart';\n" + code

# Fix photo variables
code = code.replace('final File photo;', 'final String? photoUrl;')
code = code.replace('final File? photo;', 'final String? photoUrl;')
code = code.replace('this.photo,', 'this.photoUrl,')
code = code.replace('this.photo)', 'this.photoUrl)')
code = code.replace('widget.photo!', 'widget.photoUrl!')
code = code.replace('widget.photo', 'widget.photoUrl')
code = code.replace('s.photo!', 's.photoUrl!')
code = code.replace('s.photo', 's.photoUrl')

# Fix FileImage -> NetworkImage for variables
code = code.replace('FileImage(studentPhotoUrl!)', 'NetworkImage(studentPhotoUrl!)')
code = code.replace('FileImage(adminPhotoUrl!)', 'NetworkImage(adminPhotoUrl!)')
code = code.replace('FileImage(widget.photoUrl!)', 'NetworkImage(widget.photoUrl!)')
code = code.replace('FileImage(s.photoUrl!)', 'NetworkImage(s.photoUrl!)')

# Fix SyncService deleted calls
code = code.replace('SyncService.pushMenu();', '')
code = code.replace('SyncService.pushStudents();', '')
code = code.replace('SyncService.pushAdmins();', '')

# Fix FirebaseDatabase missing
if "import 'package:firebase_database/firebase_database.dart';" not in code:
    code = "import 'package:firebase_database/firebase_database.dart';\n" + code

# Fix globalMenuUploadBytes missing
if 'Uint8List? globalMenuUploadBytes;' not in code:
    code = code.replace('bool globalMenuIsPdf = false;', 'bool globalMenuIsPdf = false;\nUint8List? globalMenuUploadBytes;')

# Fix file.path == null issue on web
code = code.replace('if (kIsWeb || file.path == null) {', 'if (kIsWeb) {')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
