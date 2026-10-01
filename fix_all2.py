import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

fd_old = '''          String formattedDate = " ,  - ";'''
fd_old_2 = '''          String formattedDate = "\ \, \ - \";'''
fd_new = '''          String formattedDate = "${DateTime.now().day} ${_getMonthName(DateTime.now().month)}, ${DateTime.now().year} - ${_getWeekdayName(DateTime.now().weekday)}";'''

code = code.replace(fd_old, fd_new)
code = code.replace(fd_old_2, fd_new)

# Fix 3: Student Logout "Existing User" UI
# Wait, why isn't existing user UI shown for students?
# Because I removed the "Not You" button? No, the issue is they logout, but maybe the UI doesn't switch properly.
# Let's inspect `_clearSavedStudent` and `Logout` button.

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Fixed formatted date.")
