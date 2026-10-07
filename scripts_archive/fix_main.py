import re

with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Image.file
content = re.sub(r'Image\.file\((.*?globalMenuFile!?)\)', r'(\1 == null || kIsWeb) ? const Icon(Icons.image, size: 50) : Image.file(\1)', content)

# 2. FileImage(...) -> ensure not null assertion if needed, but wait!
# FileImage(s.photo!) might be wrong if we just do a generic replace. Let's do specific ones:
content = content.replace("FileImage(studentPhoto!)", "FileImage(studentPhoto!)")
content = content.replace("FileImage(widget.photo)", "FileImage(widget.photo!)")
content = content.replace("FileImage(c.studentPhoto)", "FileImage(c.studentPhoto!)")
content = content.replace("FileImage(s.photo)", "FileImage(s.photo!)")
content = content.replace("FileImage(st.photo)", "FileImage(st.photo!)")

# 3. existsSync and !kIsWeb fixes
content = content.replace('if (!kIsWeb && s.photo.existsSync())', 'if (!kIsWeb && s.photo != null && s.photo!.existsSync())')
content = content.replace('!kIsWeb && st.photo.existsSync()', '!kIsWeb && st.photo != null && st.photo!.existsSync()')
content = content.replace('s.photo.existsSync() ?', '(!kIsWeb && s.photo != null && s.photo!.existsSync()) ?')

# 4. readAsBytes and path for nullable photo
content = content.replace('s.photo.readAsBytes()', 's.photo!.readAsBytes()')
content = content.replace('s.photo.path', 's.photo!.path')
content = content.replace("'photo': photo.path,", "'photo': kIsWeb ? '' : (photo?.path ?? ''),")

# 5. dummyPhoto
content = content.replace("File dummyPhoto = File('dummy.png');", "File? dummyPhoto = kIsWeb ? null : File('dummy.png');")
content = content.replace("File sPhoto = File('dummy.png');", "File? sPhoto = kIsWeb ? null : File('dummy.png');")

# 6. File(photoPath)
content = content.replace("photo: File(photoPath),", "photo: kIsWeb ? null : File(photoPath),")
content = content.replace("File(json['photo']),", "kIsWeb ? null : File(json['photo']),")

# 7. photoFile init
content = content.replace("File photoFile = File('${dir.path}/${roomNo}_${name.replaceAll(\" \", \"_\")}.jpg');", "File? photoFile;\n    if (!kIsWeb) photoFile = File('${dir.path}/${roomNo}_${name.replaceAll(\" \", \"_\")}.jpg');")

# 8. studentPhoto != null check for photo.path.contains('dummy')
content = content.replace("!existingStudent.photo.existsSync() || existingStudent.photo.path.contains('dummy')", "(!kIsWeb && (existingStudent.photo == null || !existingStudent.photo!.existsSync() || existingStudent.photo!.path.contains('dummy')))")
content = content.replace("existingStudent.photo = studentPhoto!;", "existingStudent.photo = studentPhoto;")

# 9. globalMenuFile assignment
content = content.replace("globalMenuFile = File(result.files.single.path!);", "globalMenuFile = kIsWeb ? null : File(result.files.single.path!);")

# 10. File dummy fixes
content = content.replace("File dummy = File('dummy.png');", "File? dummy = kIsWeb ? null : File('dummy.png');")

# 11. adminPhoto
content = content.replace("adminPhoto = File(image.path);", "adminPhoto = kIsWeb ? null : File(image.path);")
content = content.replace("studentPhoto = File(image.path);", "studentPhoto = kIsWeb ? null : File(image.path);")

with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done script')
