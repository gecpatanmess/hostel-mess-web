import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix my previous bad replacements
# For DecorationImage
content = content.replace(
    'image: (!kIsWeb && studentPhoto != null && studentPhoto!.existsSync()) ? FileImage(studentPhoto!) : null,',
    'image: FileImage(studentPhoto!),'
)
content = content.replace(
    'image: (!kIsWeb && adminPhoto != null && adminPhoto!.existsSync()) ? FileImage(adminPhoto!) : null,',
    'image: FileImage(adminPhoto!),'
)

# And fix the outer conditions
# For studentPhoto
content = content.replace(
    'image: studentPhoto != null\n',
    'image: (!kIsWeb && studentPhoto != null && studentPhoto!.existsSync())\n'
)
content = content.replace(
    'child: studentPhoto == null\n',
    'child: (kIsWeb || studentPhoto == null || !studentPhoto!.existsSync())\n'
)
# For adminPhoto
content = content.replace(
    'image: adminPhoto != null\n',
    'image: (!kIsWeb && adminPhoto != null && adminPhoto!.existsSync())\n'
)
content = content.replace(
    'child: adminPhoto == null\n',
    'child: (kIsWeb || adminPhoto == null || !adminPhoto!.existsSync())\n'
)

# For backgroundImage in CircleAvatar, I used `? FileImage(...) : null`.
# backgroundImage takes `ImageProvider?`, so `null` IS allowed for backgroundImage!
# Why did it fail?
# "Error: The argument type 'FileImage?' can't be assigned to the parameter type 'ImageProvider<Object>'.
#                                     image: (!kIsWeb && studentPhoto != null && studentPhoto!.existsSync()) ? FileImage(studentPhoto!) : null,"
# Ah! It failed on `image:` which is inside `DecorationImage`. `backgroundImage:` didn\'t fail!

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
