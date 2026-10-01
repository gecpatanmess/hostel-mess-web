import re
import os

filepath = 'lib/main.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. photoPath -> photoUrl in initialScreen checks
code = code.replace("if (phone != null && photoPath != null ) {", "if (phone != null && photoUrl != null ) {")
code = code.replace("if (name != null && photoPath != null && room != null ) {", "if (name != null && photoUrl != null && room != null ) {")

# 2. Fix pushStudents local variable
code = code.replace("photoUrl = s.photoUrl ?? '';", "String photoUrl = s.photoUrl ?? '';")

# 3. ComplaintItem in sample data load
old_complaint = """        globalComplaints.add(ComplaintItem(
          c['id'],
          c['title'],
          c['description'],
          DateTime.parse(c['date']),
          c['student_name'],
          c['student_room'],
          sPhoto,
        ));"""
new_complaint = """        globalComplaints.add(ComplaintItem(
          c['id'],
          c['title'],
          c['description'],
          DateTime.parse(c['date']),
          c['student_name'],
          c['student_room'],
          sPhoto,
          c['image_url'],
        ));"""
code = code.replace(old_complaint, new_complaint)

# Also fix the definition in sample data:
code = code.replace("sPhoto = globalRegisteredStudents.firstWhere((s) => s.roomNo == c['student_room'] && s.name == c['student_name']).photo;", "sPhoto = globalRegisteredStudents.firstWhere((s) => s.roomNo == c['student_room'] && s.name == c['student_name']).photoUrl;")

# 4. RegisteredStudent sample load
code = code.replace("globalRegisteredStudents.add(RegisteredStudent(name, roomNo, photoFile, pin));", "globalRegisteredStudents.add(RegisteredStudent(name, roomNo, photoFile?.path, pin));")

# 5. Fix named parameter "photo:" in screen calls
code = code.replace("photo: studentPhotoUrl", "photoUrl: studentPhotoUrl")
code = code.replace("photo: adminPhotoUrl", "photoUrl: adminPhotoUrl")
code = code.replace("photo: widget.photoUrl", "photoUrl: widget.photoUrl")

# 6. Fix .path on Strings in prefs saving
code = code.replace("studentPhotoUrl?.path ?? ''", "studentPhotoUrl ?? ''")
code = code.replace("adminPhotoUrl?.path ?? ''", "adminPhotoUrl ?? ''")

# 7. Final field complaintImageUrl is not initialized
code = code.replace("final String? complaintImageUrl;\n  ComplaintItem(", "final String? complaintImageUrl;\n  ComplaintItem(")
# Let's ensure ComplaintItem is correctly defined. I will find ComplaintItem and rewrite it.
complaint_item_regex = re.compile(r'class ComplaintItem \{.*?\n  \);', re.DOTALL)
new_complaint_item = """class ComplaintItem {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String studentName;
  final String studentRoom;
  final String? studentPhotoUrl;
  final String? complaintImageUrl;
  ComplaintItem(
    this.id,
    this.title,
    this.description,
    this.date,
    this.studentName,
    this.studentRoom,
    this.studentPhotoUrl,
    [this.complaintImageUrl]
  );"""
code = re.sub(r'class ComplaintItem \{[\s\S]*?\n  \);', new_complaint_item, code, count=1)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(code)
