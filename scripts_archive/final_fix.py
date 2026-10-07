"""
ONE SINGLE SCRIPT to fix ALL compilation errors. No more patch-on-patch.
"""
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

errors_fixed = 0

# ============ FIX 1: photoUrlUrl -> photoUrl (double-replacement bug) ============
count = code.count('photoUrlUrl')
if count > 0:
    code = code.replace('photoUrlUrl', 'photoUrl')
    errors_fixed += count
    print(f"FIX 1: Replaced {count} 'photoUrlUrl' -> 'photoUrl'")

# ============ FIX 2: Icons.photoUrl -> Icons.photo (wrong replacement) ============
count = code.count('Icons.photoUrl')
if count > 0:
    code = code.replace('Icons.photoUrl', 'Icons.photo')
    errors_fixed += count
    print(f"FIX 2: Replaced {count} 'Icons.photoUrl' -> 'Icons.photo'")

# ============ FIX 3: FileImage(widget.photoUrl) -> NetworkImage (type mismatch) ============
for old, new in [
    ('FileImage(widget.photoUrl!)', 'NetworkImage(widget.photoUrl!)'),
    ('FileImage(widget.photoUrl)', 'NetworkImage(widget.photoUrl ?? "")'),
    ('FileImage(s.photoUrl!)', 'NetworkImage(s.photoUrl!)'),
    ('FileImage(s.photoUrl)', 'NetworkImage(s.photoUrl ?? "")'),
    ('FileImage(studentPhotoUrl!)', 'NetworkImage(studentPhotoUrl!)'),
    ('FileImage(adminPhotoUrl!)', 'NetworkImage(adminPhotoUrl!)'),
]:
    c = code.count(old)
    if c > 0:
        code = code.replace(old, new)
        errors_fixed += c
        print(f"FIX 3: Replaced {c} '{old}' -> '{new}'")

# ============ FIX 4: Add missing state variables for saved credentials ============
if 'bool hasSavedStudent' not in code:
    old_state = """  bool isStudent = true;
  bool isStudentPinVisible = false;
  bool isAdminPassVisible = false;
  bool _studentEmailVerified = false;
  bool _adminEmailVerified = false;
  bool _isVerifyingEmail = false;
  String? selectedStudentName;"""
    
    new_state = """  bool isStudent = true;
  bool isStudentPinVisible = false;
  bool isAdminPassVisible = false;
  bool _studentEmailVerified = false;
  bool _adminEmailVerified = false;
  bool _isVerifyingEmail = false;
  String? selectedStudentName;

  bool hasSavedStudent = false;
  String? savedStudentName;
  String? savedStudentRoom;
  String? savedStudentPhoto;

  bool hasSavedAdmin = false;
  String? savedAdminPhone;
  String? savedAdminName;
  String? savedAdminPhoto;"""
    
    if old_state in code:
        code = code.replace(old_state, new_state)
        errors_fixed += 1
        print("FIX 4: Added saved credential state variables")
    else:
        print("FIX 4: WARNING - Could not find state variables block to inject into")

# ============ FIX 5: Add initState and helper methods ============
if '_loadSavedCredentials' not in code:
    init_block = """
  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedStudentName = prefs.getString('last_student_name');
      savedStudentRoom = prefs.getString('last_student_room');
      savedStudentPhoto = prefs.getString('last_student_photo');
      hasSavedStudent = savedStudentName != null && savedStudentName!.isNotEmpty;

      savedAdminPhone = prefs.getString('last_admin_phone');
      savedAdminName = prefs.getString('last_admin_name');
      savedAdminPhoto = prefs.getString('last_admin_photo');
      hasSavedAdmin = savedAdminPhone != null && savedAdminPhone!.isNotEmpty;

      if (hasSavedStudent) {
        selectedRoom = savedStudentRoom;
        selectedStudentName = savedStudentName;
        studentPhotoUrl = savedStudentPhoto;
        isStudent = true;
      }
      if (hasSavedAdmin) {
        _adminMobileController.text = savedAdminPhone!;
        _adminNameController.text = savedAdminName ?? "";
        adminPhotoUrl = savedAdminPhoto;
        isStudent = false;
      }
    });
  }

  void _clearSavedStudent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_student_name');
    await prefs.remove('last_student_room');
    await prefs.remove('last_student_photo');
    setState(() {
      hasSavedStudent = false;
      selectedRoom = null;
      selectedStudentName = null;
      studentPhotoUrl = null;
      _studentPinController.clear();
      _studentEmailVerified = false;
    });
  }

  void _clearSavedAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_admin_phone');
    await prefs.remove('last_admin_name');
    await prefs.remove('last_admin_photo');
    setState(() {
      hasSavedAdmin = false;
      _adminMobileController.clear();
      _adminNameController.clear();
      adminPhotoUrl = null;
      _adminPasswordController.clear();
      _adminEmailVerified = false;
    });
  }

"""
    target = "  Future<void> _pickImage(bool isStudentForm) async {"
    if target in code:
        code = code.replace(target, init_block + "  Future<void> _pickImage(bool isStudentForm) async {")
        errors_fixed += 1
        print("FIX 5: Added initState and saved credential helpers")
    else:
        print("FIX 5: WARNING - Could not find _pickImage to inject before")

# ============ FIX 6: ViewMenuTab onEditMenu parameter ============
# Remove onEditMenu parameter from ViewMenuTab calls since it's not defined
code = code.replace('ViewMenuTab(onEditMenu: null)', 'const ViewMenuTab()')
code = code.replace('ViewMenuTab(onEditMenu: _showSetMenuDialog)', 'const ViewMenuTab()')
count_fix = code.count('ViewMenuTab(onEditMenu:')
if count_fix == 0:
    print("FIX 6: Fixed ViewMenuTab onEditMenu parameters")
    errors_fixed += 1

# ============ FIX 7: globalMenuUrl -> use globalMenuFile or remove ============
if 'String? globalMenuUrl;' not in code:
    # Add the variable definition
    code = code.replace('String? globalMenuFile;', 'String? globalMenuFile;\nString? globalMenuUrl;')
    if 'String? globalMenuUrl;' not in code:
        # Try alternate location
        code = code.replace('bool globalMenuIsPdf = false;', 'bool globalMenuIsPdf = false;\nString? globalMenuUrl;')
    print("FIX 7: Added globalMenuUrl variable definition")
    errors_fixed += 1

# ============ FIX 8: photo: -> photoUrl: in constructor calls ============
# Only fix named parameters, not things like "Upload Admin Photo:"
code = code.replace('photo: studentPhoto!,', 'photoUrl: studentPhotoUrl,')
code = code.replace('photo: adminPhoto!,', 'photoUrl: adminPhotoUrl,')
code = code.replace('photo: widget.photoUrl,', 'photoUrl: widget.photoUrl,')

# Fix existingStudent.photo -> existingStudent.photoUrl
code = code.replace('existingStudent.photo;', 'existingStudent.photoUrl;')
code = code.replace('existingStudent.photo,', 'existingStudent.photoUrl,')

print(f"FIX 8: Fixed named parameter 'photo:' -> 'photoUrl:'")
errors_fixed += 1

# ============ FIX 9: Ensure imports ============
if "import 'package:flutter/foundation.dart';" not in code:
    code = "import 'package:flutter/foundation.dart';\n" + code
    print("FIX 9a: Added foundation.dart import")

if "import 'package:firebase_database/firebase_database.dart';" not in code:
    code = "import 'package:firebase_database/firebase_database.dart';\n" + code
    print("FIX 9b: Added firebase_database import")

# ============ FIX 10: Student login save credentials ============
old_save = """    await prefs.setString('userType', 'student');
    await prefs.setString('identifier', typedName);
    await prefs.setString('photoPath', studentPhotoUrl ?? '');
    await prefs.setString('extraInfo', selectedRoom!);"""
new_save = """    await prefs.setString('userType', 'student');
    await prefs.setString('identifier', typedName);
    await prefs.setString('photoPath', studentPhotoUrl ?? '');
    await prefs.setString('extraInfo', selectedRoom!);

    await prefs.setString('last_student_name', typedName);
    await prefs.setString('last_student_room', selectedRoom!);
    await prefs.setString('last_student_photo', studentPhotoUrl ?? '');"""
if old_save in code and 'last_student_name' not in code:
    code = code.replace(old_save, new_save)
    print("FIX 10a: Added student save credentials")

old_admin_save = """          await prefs.setString('userType', 'admin');
          await prefs.setString('identifier', admin.phone);
          await prefs.setString('photoPath', adminPhotoUrl ?? '');
          await prefs.setString('extraInfo', _adminNameController.text);"""
new_admin_save = """          await prefs.setString('userType', 'admin');
          await prefs.setString('identifier', admin.phone);
          await prefs.setString('photoPath', adminPhotoUrl ?? '');
          await prefs.setString('extraInfo', _adminNameController.text);

          await prefs.setString('last_admin_phone', admin.phone);
          await prefs.setString('last_admin_name', _adminNameController.text);
          await prefs.setString('last_admin_photo', adminPhotoUrl ?? '');"""
if old_admin_save in code and 'last_admin_phone' not in code:
    code = code.replace(old_admin_save, new_admin_save)
    print("FIX 10b: Added admin save credentials")

# ============ WRITE ============
with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print(f"\n=== TOTAL: {errors_fixed} fixes applied ===")
