import sys
import io
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add logic to _buildStudentPortal
search1 = "  Widget _buildStudentPortal() {\n    return Container("
replace1 = """  Widget _buildStudentPortal() {
    bool isRegisteredStudent = false;
    String? existingPhoto;
    if (selectedRoom != null && selectedStudentName != null) {
      try {
        final st = globalRegisteredStudents.firstWhere(
          (s) => s.roomNo == selectedRoom && s.name == selectedStudentName
        );
        if (st.pin.isNotEmpty) {
          isRegisteredStudent = true;
          existingPhoto = st.photoUrl;
        }
      } catch(e) {}
    }
    bool canUploadPhoto = !isRegisteredStudent || (existingPhoto == null || existingPhoto.isEmpty);
    String? displayPhotoUrl = (isRegisteredStudent && !canUploadPhoto) ? existingPhoto : studentPhotoUrl;

    return Container("""
content = content.replace(search1, replace1)

# 2. Update GestureDetector in StudentPortal
search2 = """                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE9D2),
                            shape: BoxShape.circle,
                            image: (studentPhotoUrl != null && studentPhotoUrl!.isNotEmpty) ? DecorationImage(image: NetworkImage(studentPhotoUrl!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: (studentPhotoUrl == null || studentPhotoUrl!.isEmpty)
                              ? const Icon(
                                  Icons.camera_alt_outlined,
                                  color: brandOrange,
                                  size: 38,
                                )
                              : null,
                        ),
                        Positioned("""
replace2 = """                  GestureDetector(
                    onTap: canUploadPhoto ? () => _pickImage(true) : () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot change your photo after registration.'), backgroundColor: brandOrange));
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE9D2),
                            shape: BoxShape.circle,
                            image: (displayPhotoUrl != null && displayPhotoUrl.isNotEmpty) ? DecorationImage(image: NetworkImage(displayPhotoUrl), fit: BoxFit.cover)
                                : null,
                          ),
                          child: (displayPhotoUrl == null || displayPhotoUrl.isEmpty)
                              ? const Icon(
                                  Icons.camera_alt_outlined,
                                  color: brandOrange,
                                  size: 38,
                                )
                              : null,
                        ),
                        if (canUploadPhoto)
                          Positioned("""
content = content.replace(search2, replace2)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated _buildStudentPortal UI")
