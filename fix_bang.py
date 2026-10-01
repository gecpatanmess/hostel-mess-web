import re
import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace studentPhoto! with studentPhoto where appropriate
content = content.replace('RegisteredStudent(typedName, selectedRoom!, studentPhoto!, typedPin)', 'RegisteredStudent(typedName, selectedRoom!, studentPhoto, typedPin)')
content = content.replace("await prefs.setString('photoPath', studentPhoto!.path);", "await prefs.setString('photoPath', studentPhoto?.path ?? '');")
content = content.replace("await prefs.setString('photoPath', adminPhoto!.path);", "await prefs.setString('photoPath', adminPhoto?.path ?? '');")
content = content.replace("photo: studentPhoto!,", "photo: studentPhoto,")
content = content.replace("photo: adminPhoto!,", "photo: adminPhoto,")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done replacing !")
