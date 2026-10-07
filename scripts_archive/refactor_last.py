import re

filepath = 'lib/main.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Fix photoUrl undefined in pushStudents
old_push_students = """        if (!kIsWeb && s.photoUrl != null && s.photoUrl!.isNotEmpty) {
          try {
            // Keep base64 short or just use a placeholder if hashing is too slow. 
            // Actually, reading file every second is bad.
            // Let's just track the path length for hash.
            photoUrl = s.photoUrl ?? '';
          } catch(e){}
        }"""
new_push_students = """        String photoUrl = s.photoUrl ?? '';"""
code = code.replace(old_push_students, new_push_students)

# Just in case there is a stray photoUrl = s.photoUrl ?? ''; without String
code = code.replace("photoUrl = s.photoUrl ?? '';\n        studentsList.add({\n          'name': s.name,\n          'roomNo': s.roomNo,\n          'pin': s.pin,\n          'photoUrl': photoUrl,\n        });", "String photoUrl = s.photoUrl ?? '';\n        studentsList.add({\n          'name': s.name,\n          'roomNo': s.roomNo,\n          'pin': s.pin,\n          'photoUrl': photoUrl,\n        });")

# 2. Fix File? sPhoto -> String? sPhotoUrl
code = code.replace("File? sPhoto;", "String? sPhoto;")

# 3. Remove final String? complaintImageUrl; from _LoginScreenState
code = code.replace("  String? studentPhotoUrl;\n  final String? complaintImageUrl;\n  String? adminPhotoUrl;", "  String? studentPhotoUrl;\n  String? adminPhotoUrl;")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(code)
