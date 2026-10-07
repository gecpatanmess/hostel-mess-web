import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# For all StatefulWidgets, change inal File photo; to inal String photoUrl;
# and 	his.photo to 	his.photoUrl in constructors.
code = code.replace("final File photo;", "final String photoUrl;")
code = code.replace("final File? photo;", "final String? photoUrl;")
code = code.replace("this.photo,", "this.photoUrl,")
code = code.replace("this.photo)", "this.photoUrl)")

# For FileImage(widget.photoUrl!), since it's a URL, we can't use FileImage. We should use NetworkImage or Image.network!
# Let's replace FileImage(widget.photoUrl!) with NetworkImage(widget.photoUrl!)
code = code.replace("FileImage(widget.photoUrl!)", "NetworkImage(widget.photoUrl!)")
code = code.replace("FileImage(widget.photo!)", "NetworkImage(widget.photoUrl!)")
code = code.replace("widget.photo!", "widget.photoUrl!")
code = code.replace("widget.photo", "widget.photoUrl")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Fixed photo references!")
