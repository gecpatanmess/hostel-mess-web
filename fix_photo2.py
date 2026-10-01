import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace any occurrence of 'final File photo;' or 'final File? photo;' with 'final String? photoUrl;'
code = re.sub(r'final File\?? photo;', r'final String? photoUrl;', code)

# Just in case, replace 'final File' with 'final String?' for photo
code = re.sub(r'final\s+File\s+photo\s*;', r'final String? photoUrl;', code)
code = re.sub(r'final\s+File\?\s+photo\s*;', r'final String? photoUrl;', code)

# Ensure constructors take photoUrl
code = re.sub(r'this\.photo,', r'this.photoUrl,', code)
code = re.sub(r'this\.photo\)', r'this.photoUrl)', code)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Fixed photo properly!")
