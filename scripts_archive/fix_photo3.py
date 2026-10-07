with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(len(lines)):
    if 'final File photo;' in lines[i]:
        lines[i] = lines[i].replace('final File photo;', 'final String? photoUrl;')
    if 'final File? photo;' in lines[i]:
        lines[i] = lines[i].replace('final File? photo;', 'final String? photoUrl;')
    if 'this.photo,' in lines[i]:
        lines[i] = lines[i].replace('this.photo,', 'this.photoUrl,')
    if 'this.photo)' in lines[i]:
        lines[i] = lines[i].replace('this.photo)', 'this.photoUrl)')
    if 'FileImage(widget.photoUrl!)' in lines[i]:
        lines[i] = lines[i].replace('FileImage(widget.photoUrl!)', 'NetworkImage(widget.photoUrl!)')
    if 'FileImage(s.photoUrl!)' in lines[i]:
        lines[i] = lines[i].replace('FileImage(s.photoUrl!)', 'NetworkImage(s.photoUrl!)')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
print("Replaced line by line!")
