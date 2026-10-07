with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

checks = [
    'photoUrlUrl',
    'Icons.photoUrl',
    'FileImage(widget.photoUrl',
    'FileImage(s.photoUrl',
    'ViewMenuTab(onEditMenu',
    'bool hasSavedStudent',
    'String? savedStudentName',
    'String? globalMenuUrl',
    '_loadSavedCredentials',
    'class EmailOtpService',
    'class AboutDevelopersScreen',
    'final File photo;',
    'photo: studentPhoto',
    'photo: adminPhoto',
]
for c in checks:
    print(f"  {c}: {code.count(c)}")
