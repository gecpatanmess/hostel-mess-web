import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

search_handle = """      if (studentPhotoUrl == null) {
        // Check if existing photo actually exists on disk
        if ((existingStudent.photoUrl == null || existingStudent.photoUrl!.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please upload your photo to continue.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        studentPhotoUrl = existingStudent.photoUrl;
      } else {
        existingStudent.photoUrl = studentPhotoUrl;
      }
      await saveRegisteredStudents();
      SyncService.pushStudents();"""
      
replace_handle = """      if (existingStudent.photoUrl == null || existingStudent.photoUrl!.isEmpty) {
        if (studentPhotoUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please upload your photo to continue.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        existingStudent.photoUrl = studentPhotoUrl;
      } else {
        studentPhotoUrl = existingStudent.photoUrl; // Use existing photo unconditionally
      }
      await saveRegisteredStudents();
      SyncService.pushStudents();"""

if search_handle in content:
    content = content.replace(search_handle, replace_handle)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated _handleStudentLogin logic")
else:
    print("search_handle not found")
