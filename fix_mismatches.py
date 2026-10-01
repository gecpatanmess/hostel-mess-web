import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix RegisteredStudent
code = code.replace("final File photo;", "final String photoUrl;")
code = code.replace("this.photo,", "this.photoUrl,")

# Fix AdminDashboardScreen
code = code.replace("final File photo;", "final String photoUrl;")

# Fix StudentComplaintsScreen (it probably has similar issue)
code = code.replace("class StudentComplaintsScreen extends StatefulWidget {\n  final File photo;", "class StudentComplaintsScreen extends StatefulWidget {\n  final String photoUrl;")
code = code.replace("class StudentComplaintsScreen extends StatefulWidget {\r\n  final File photo;", "class StudentComplaintsScreen extends StatefulWidget {\n  final String photoUrl;")

# Fix MealPassScreen
code = code.replace("class MealPassScreen extends StatefulWidget {\n  final File photo;", "class MealPassScreen extends StatefulWidget {\n  final String photoUrl;")
code = code.replace("class MealPassScreen extends StatefulWidget {\r\n  final File photo;", "class MealPassScreen extends StatefulWidget {\n  final String photoUrl;")

# Anywhere it expects widget.photo, change to widget.photoUrl in these screens?
# The error was "The getter 'photoUrl' isn't defined for the type 'AdminDashboardScreen'". This is because the field was photo, but the code was doing widget.photoUrl!
# So changing the field to photoUrl fixes it!

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Fixed constructors!")
