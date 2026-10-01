import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Let's search for "About Developers" in the code
matches = re.finditer(r'ListTile\(\s*leading:\s*const\s*Icon\(Icons\.info_outline\),\s*title:\s*const\s*Text\(\'About Developers\'\)', content)
count = sum(1 for _ in matches)
print(f"Found 'About Developers' ListTile {count} times.")

# Also check for AdminDashboardScreen drawer
admin_drawer = re.search(r'class AdminDashboardScreen.*?Widget _buildAdminDrawer.*?About Developers', content, re.DOTALL)
student_drawer = re.search(r'class StudentDashboardScreen.*?Widget _buildStudentDrawer.*?About Developers', content, re.DOTALL)

if admin_drawer:
    print("Found in Admin drawer")
else:
    print("NOT found in Admin drawer")
    
if student_drawer:
    print("Found in Student drawer")
else:
    print("NOT found in Student drawer")
