with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old_block = """              title: const Text(
                'Set Menu',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSetMenuDialog();
              },
            ),
            Builder("""

new_block = """              title: const Text(
                'Set Menu (Today)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSetMenuDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar, color: brandDark),
              title: const Text(
                'Edit Weekly Timetable',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (context) => const WeeklyMenuEditorWidget());
              },
            ),
            Builder("""

code = code.replace(old_block, new_block)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Weekly Menu button injected!")
