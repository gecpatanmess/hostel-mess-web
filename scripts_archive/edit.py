import re

with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

print('Original length:', len(content))

content = re.sub(
    r"final pinCtrl = TextEditingController\(text: student\?\.pin \?\? ''\);",
    r" ",
    content
)

content = re.sub(
    r"TextField\(controller: pinCtrl, decoration: const InputDecoration\(labelText: 'PIN'\)\),",
    r" ",
    content
)

content = re.sub(
    r"if \(nameCtrl\.text\.isEmpty \|\| roomCtrl\.text\.isEmpty \|\| pinCtrl\.text\.isEmpty\) \{\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\(const SnackBar\(content: Text\('Name, Room No, and PIN are required'\)\)\);\s*return;\s*\}",
    r"if (nameCtrl.text.isEmpty || roomCtrl.text.isEmpty) {\n                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Room No are required')));\n                return;\n              }",
    content
)

content = re.sub(
    r"globalRegisteredStudents\.add\(RegisteredStudent\(nameCtrl\.text, roomCtrl\.text, null, pinCtrl\.text\)\);",
    r"globalRegisteredStudents.add(RegisteredStudent(nameCtrl.text, roomCtrl.text, null, ''));",
    content
)

content = re.sub(
    r"globalRegisteredStudents\[idx\] = RegisteredStudent\(nameCtrl\.text, roomCtrl\.text, student\.photoUrl, pinCtrl\.text, email: student\.email\);",
    r"globalRegisteredStudents[idx] = RegisteredStudent(nameCtrl.text, roomCtrl.text, student.photoUrl, student.pin, email: student.email);",
    content
)

content = re.sub(
    r"subtitle: Text\('Room: \$\{s\.roomNo\} \| PIN: \$\{s\.pin\}'\),",
    r"subtitle: Text('Room: ${s.roomNo} | PIN: ${s.pin == \'\' ? \'Not Set\' : \'Set (Hidden)\'}'),",
    content
)


# ==========================================
# 2. Add _isCreatingPassword logic
# Find:
#   bool isStudent = true;
#   bool isStudentPinVisible = false;

content = re.sub(
    r"bool isStudent = true;\s*bool isStudentPinVisible = false;",
    r"bool isStudent = true;\n  bool _isCreatingPassword = false;\n  bool isStudentPinVisible = false;",
    content
)

# Update _isCreatingPassword on dropdown change
#                     onChanged: (val) {
#                       setState(() {
#                         selectedStudentName = val;
#                       });
#                     },

new_on_change = r"""                    onChanged: (val) {
                      setState(() {
                        selectedStudentName = val;
                        if (val != null && selectedRoom != null) {
                           try {
                             var s = globalRegisteredStudents.firstWhere((st) => st.roomNo == selectedRoom && st.name == val);
                             _isCreatingPassword = s.pin.isEmpty;
                           } catch (e) {
                             _isCreatingPassword = false;
                           }
                        } else {
                           _isCreatingPassword = false;
                        }
                      });
                    },"""

content = re.sub(
    r"onChanged: \(val\) \{\s*setState\(\(\) \{\s*selectedStudentName = val;\s*\}\);\s*\},",
    new_on_change,
    content
)

# Also update when room is changed, just in case (optional but good practice)
#                     onChanged: (val) {
#                       setState(() {
#                         selectedRoom = val;
#                         selectedStudentName = null;
#                       });
#                     },
new_room_on_change = r"""                    onChanged: (val) {
                      setState(() {
                        selectedRoom = val;
                        selectedStudentName = null;
                        _isCreatingPassword = false;
                      });
                    },"""
content = re.sub(
    r"onChanged: \(val\) \{\s*setState\(\(\) \{\s*selectedRoom = val;\s*selectedStudentName = null;\s*\}\);\s*\},",
    new_room_on_change,
    content
)


# Hide Email and Re-Pin if not _isCreatingPassword
content = re.sub(
    r"if \(\!hasSavedStudent\) \.\.\.\[",
    r"if (!hasSavedStudent && _isCreatingPassword) ...[",
    content
)

# In `_handleStudentLogin`:
#     if (!hasSavedStudent && !_studentEmailVerified) {
# to
#     bool needsEmailAndRePin = false;
#     try {
#       var s = globalRegisteredStudents.firstWhere((st) => st.roomNo == selectedRoom && st.name == selectedStudentName);
#       needsEmailAndRePin = s.pin.isEmpty;
#     } catch (e) {}
#     if (!hasSavedStudent && needsEmailAndRePin && !_studentEmailVerified) {

new_validation_logic = r"""    bool needsEmailAndRePin = false;
    try {
      var s = globalRegisteredStudents.firstWhere((st) => st.roomNo == selectedRoom && st.name == selectedStudentName);
      needsEmailAndRePin = s.pin.isEmpty;
    } catch (e) {}

    // Email verification check
    if (!hasSavedStudent && needsEmailAndRePin && !_studentEmailVerified) {"""

content = re.sub(
    r"// Email verification check\s*if \(\!hasSavedStudent && \!_studentEmailVerified\) \{",
    new_validation_logic,
    content
)


with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('New length:', len(content))


with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 3. Hash Student Passwords
# In _handleStudentLogin:
# existingStudent.pin = typedPin;
# -> existingStudent.pin = hashedTypedPin;
content = re.sub(
    r"existingStudent\.pin = typedPin;",
    r"existingStudent.pin = hashedTypedPin;",
    content
)

# And in `else if (existingStudent.pin != typedPin)`
# We need to change to:
# `else if (existingStudent.pin != typedPin && existingStudent.pin != hashedTypedPin)`
# and then if it's the old plaintext `existingStudent.pin == typedPin`, we can hash it.
new_password_check = r"""      } else if (existingStudent.pin != typedPin && existingStudent.pin != hashedTypedPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Wrong Password! Please enter your correct 8-character password.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      } else if (existingStudent.pin == typedPin) {
        // Upgrade legacy plaintext to hash
        existingStudent.pin = hashedTypedPin;
      }"""

content = re.sub(
    r"\} else if \(existingStudent\.pin \!\= typedPin\) \{[\s\S]*?return;\s*\}",
    new_password_check,
    content
)

# And for new student:
# globalRegisteredStudents.add(
#   RegisteredStudent(typedName, selectedRoom!, studentPhotoUrl, typedPin, email: _studentEmailController.text.trim()),
# );
# -> hashedTypedPin
content = re.sub(
    r"globalRegisteredStudents\.add\(\s*RegisteredStudent\(typedName, selectedRoom\!, studentPhotoUrl, typedPin, email: _studentEmailController\.text\.trim\(\)\),\s*\);",
    r"globalRegisteredStudents.add(\n        RegisteredStudent(typedName, selectedRoom!, studentPhotoUrl, hashedTypedPin, email: _studentEmailController.text.trim()),\n      );",
    content
)

# And for Forgot Password (isStudentReq)
# existingStudent.pin = newPassCtrl.text; -> hashPassword(newPassCtrl.text)
content = re.sub(
    r"existingStudent\.pin = newPassCtrl\.text;",
    r"existingStudent.pin = hashPassword(newPassCtrl.text);",
    content
)
# For Admin Forgot Password
# admin.pin = newPassCtrl.text; -> hashPassword(newPassCtrl.text)
content = re.sub(
    r"admin\.pin = newPassCtrl\.text;",
    r"admin.pin = hashPassword(newPassCtrl.text);",
    content
)


with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Final length:', len(content))
