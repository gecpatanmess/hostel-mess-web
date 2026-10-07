import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

old_code = """      if (hasSavedStudent) {
        selectedRoom = savedStudentRoom;
        selectedStudentName = savedStudentName;
        studentPhotoUrl = savedStudentPhoto;
      }
      if (hasSavedAdmin) {
        _adminMobileController.text = savedAdminPhone!;
        _adminNameController.text = savedAdminName ?? "";
        adminPhotoUrl = savedAdminPhoto;
      }"""

new_code = """      if (hasSavedStudent) {
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
      }"""

code = code.replace(old_code, new_code)
with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
print("State isStudent fixed!")
