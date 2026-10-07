import re
import os

filepath = 'lib/main.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Models & Global variables
code = code.replace('File? studentPhoto;', 'String? studentPhotoUrl;\n  final String? complaintImageUrl;')
code = code.replace('this.studentPhoto,\n  );', 'this.studentPhotoUrl,\n    this.complaintImageUrl,\n  );')

code = code.replace('File? photo;', 'String? photoUrl;')
code = code.replace('RegisteredStudent(this.name, this.roomNo, this.photo, this.pin);', 'RegisteredStudent(this.name, this.roomNo, this.photoUrl, this.pin);')

# In toJson
code = code.replace("'photo': kIsWeb ? '' : (photo?.path ?? ''),", "'photoUrl': photoUrl ?? '',")
code = code.replace("kIsWeb ? null : File(json['photo']),", "json['photoUrl'] ?? json['photo'],")

# In fake students
code = code.replace("File? dummyPhoto = kIsWeb ? null : File('dummy.png');", "String? dummyPhoto = null;")

# In initialScreen checks
code = code.replace("String? photoPath = prefs.getString('photoPath');", "String? photoUrl = prefs.getString('photoUrl');")
code = code.replace("photo: kIsWeb ? null : File(photoPath),", "photoUrl: photoUrl,")

# 2. SyncService image uploading
sync_service_helper = """
  static Future<String?> uploadImage(Uint8List bytes) async {
    try {
      final path = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('mess_images').uploadBinary(path, bytes);
      return _supabase.storage.from('mess_images').getPublicUrl(path);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }
"""

if 'static Future<String?> uploadImage' not in code:
    code = code.replace('class SyncService {', 'class SyncService {\n' + sync_service_helper)

# 3. pushComplaints
code = code.replace(
    "String photoUrl = \"\"; // upload to storage if needed, but skipping base64 logic to keep it fast",
    "String photoUrl = c.complaintImageUrl ?? \"\";"
)

old_push_complaints = """    List<Map<String, dynamic>> cList = [];
    for (var c in globalComplaints) {
      cList.add({
        'id': c.id,
        'title': c.title,
        'description': c.description,
        'date': c.date.toIso8601String(),
        'studentName': c.studentName,
        'studentRoom': c.studentRoom
      });
    }"""
new_push_complaints = """    List<Map<String, dynamic>> cList = [];
    for (var c in globalComplaints) {
      cList.add({
        'id': c.id,
        'title': c.title,
        'description': c.description,
        'date': c.date.toIso8601String(),
        'studentName': c.studentName,
        'studentRoom': c.studentRoom,
        'studentPhotoUrl': c.studentPhotoUrl,
        'complaintImageUrl': c.complaintImageUrl,
      });
    }"""
code = code.replace(old_push_complaints, new_push_complaints)

# 4. pushStudents
old_push_students = """        String photoBase64 = "";
        if (!kIsWeb && s.photo != null && s.photo!.existsSync()) {
          try {
            // Keep base64 short or just use a placeholder if hashing is too slow. 
            // Actually, reading file every second is bad.
            // Let's just track the path length for hash.
            photoBase64 = s.photo!.path;
          } catch(e){}
        }"""
new_push_students = """        String photoUrl = s.photoUrl ?? "";"""
code = code.replace(old_push_students, new_push_students)

old_push_students_2 = """        String photoBase64 = "";
        if (!kIsWeb && s.photo != null && s.photo!.existsSync()) {
          try {
            photoBase64 = base64Encode(await s.photo!.readAsBytes());
          } catch(e){}
        }"""
new_push_students_2 = """        String photoUrl = s.photoUrl ?? "";"""
code = code.replace(old_push_students_2, new_push_students_2)

code = code.replace("'photoBase64': photoBase64", "'photoUrl': photoUrl")

# 5. Admin and Student Dashboard photo field types
code = code.replace("final File? photo;", "final String? photoUrl;")
code = code.replace("final File? adminPhoto;", "final String? adminPhotoUrl;")
code = code.replace("final File? studentPhoto;", "final String? studentPhotoUrl;")

# Replace constructor parameters for screens
code = code.replace("this.photo,", "this.photoUrl,")

# State fields
code = code.replace("File? studentPhoto;", "String? studentPhotoUrl;")
code = code.replace("File? adminPhoto;", "String? adminPhotoUrl;")

# Login form image picker logic
old_pick = """  Future<void> _pickImage(bool isStudentForm) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isStudentForm) {
          studentPhoto = kIsWeb ? null : File(image.path);
        } else {
          adminPhoto = kIsWeb ? null : File(image.path);
        }
      });
    }
  }"""

new_pick = """  Future<void> _pickImage(bool isStudentForm) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 800,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      final url = await SyncService.uploadImage(bytes);
      if (url != null) {
        setState(() {
          if (isStudentForm) {
            studentPhotoUrl = url;
          } else {
            adminPhotoUrl = url;
          }
        });
      }
    }
  }"""
code = code.replace(old_pick, new_pick)

# Replacing SharedPreferences saving
code = code.replace("prefs.setString('photoPath', kIsWeb ? '' : (existingStudent.photo?.path ?? ''));", "prefs.setString('photoUrl', existingStudent.photoUrl ?? '');")
code = code.replace("prefs.setString('photoPath', kIsWeb ? '' : (adminPhoto?.path ?? ''));", "prefs.setString('photoUrl', adminPhotoUrl ?? '');")
code = code.replace("prefs.setString('photoPath', kIsWeb ? '' : (studentPhoto?.path ?? ''));", "prefs.setString('photoUrl', studentPhotoUrl ?? '');")

# Admin photo when registering
code = code.replace(
    """      globalRegisteredStudents.add(RegisteredStudent(
        typedName,
        selectedRoom!,
        studentPhoto,
        typedPin,
      ));""",
    """      globalRegisteredStudents.add(RegisteredStudent(
        typedName,
        selectedRoom!,
        studentPhotoUrl,
        typedPin,
      ));"""
)
code = code.replace("widget.photo", "widget.photoUrl")

# CircleAvatar replacements
def avatar_replacement(match):
    prefix = match.group(1)
    var_name = match.group(2)
    return f"""{prefix}child: ({var_name} != null && {var_name}!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        {var_name}!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),"""

code = re.sub(
    r'(CircleAvatar\s*\([^)]*?)backgroundImage:\s*\(!kIsWeb\s*&&\s*([a-zA-Z0-9_\.]+)\s*!=\s*null\s*&&\s*\2!\.existsSync\(\)\)\s*\?\s*FileImage\(\2!\)\s*:\s*null,',
    avatar_replacement,
    code,
    flags=re.DOTALL
)

code = code.replace("child: (!kIsWeb && c.studentPhotoUrl != null && c.studentPhotoUrl!.existsSync()) ? null : const Icon(Icons.person, color: Colors.white),", "")
code = code.replace("child: (!kIsWeb && s.photoUrl != null && s.photoUrl!.existsSync()) ? null : const Icon(Icons.person, color: Colors.white),", "")
code = code.replace("child: (!kIsWeb && st.photoUrl != null && st.photoUrl!.existsSync()) ? null : const Icon(Icons.person, color: Colors.white, size: 20),", "")

code = re.sub(
    r'image:\s*\(!kIsWeb\s*&&\s*([a-zA-Z0-9_]+)\s*!=\s*null\s*&&\s*\1!\.existsSync\(\)\)\s*\?\s*DecorationImage\(\s*image:\s*FileImage\(\1!\),\s*fit:\s*BoxFit\.cover,\s*\)',
    r'image: (\1 != null && \1!.isNotEmpty) ? DecorationImage(image: NetworkImage(\1!), fit: BoxFit.cover)',
    code,
    flags=re.DOTALL
)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(code)
