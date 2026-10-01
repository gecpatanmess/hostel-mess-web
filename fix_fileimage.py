with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace("FileImage(studentPhotoUrl!)", "NetworkImage(studentPhotoUrl!)")
code = code.replace("FileImage(adminPhotoUrl!)", "NetworkImage(adminPhotoUrl!)")
code = code.replace("FileImage(widget.photoUrl!)", "NetworkImage(widget.photoUrl!)")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
