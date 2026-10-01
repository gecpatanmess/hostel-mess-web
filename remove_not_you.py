with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace Not you for student
student_not_you = '''              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.restaurant, color: brandOrange, size: 22),
                      SizedBox(width: 10),
                      Text("Student Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark)),
                    ],
                  ),
                  if (hasSavedStudent)
                    TextButton(
                      onPressed: _clearSavedStudent,
                      child: const Text("Not you?", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    )
                ],
              ),'''

student_not_you_new = '''              const Row(
                children: [
                  Icon(Icons.restaurant, color: brandOrange, size: 22),
                  SizedBox(width: 10),
                  Text("Student Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark)),
                ],
              ),'''
code = code.replace(student_not_you, student_not_you_new)

# Replace Not you for admin
admin_not_you = '''              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.admin_panel_settings, color: brandOrange, size: 22),
                      SizedBox(width: 10),
                      Text("Admin Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark)),
                    ],
                  ),
                  if (hasSavedAdmin)
                    TextButton(
                      onPressed: _clearSavedAdmin,
                      child: const Text("Not you?", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    )
                ],
              ),'''

admin_not_you_new = '''              const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: brandOrange, size: 22),
                  SizedBox(width: 10),
                  Text("Admin Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark)),
                ],
              ),'''
code = code.replace(admin_not_you, admin_not_you_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Removed 'Not you?' button")
