import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

weekly_widget_code = """
class WeeklyMenuEditorWidget extends StatefulWidget {
  const WeeklyMenuEditorWidget({super.key});
  @override
  _WeeklyMenuEditorWidgetState createState() => _WeeklyMenuEditorWidgetState();
}

class _WeeklyMenuEditorWidgetState extends State<WeeklyMenuEditorWidget> {
  int _selectedDay = DateTime.now().weekday;
  final _bfCtrl = TextEditingController();
  final _luCtrl = TextEditingController();
  final _dnCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDayMenu();
  }

  void _loadDayMenu() async {
    setState(() => _isLoading = true);
    
    // Default fallback
    final fallback = defaultWeeklyMenu[_selectedDay] ?? defaultWeeklyMenu[DateTime.monday]!;
    String bf = fallback['breakfast']!;
    String lu = fallback['lunch']!;
    String dn = fallback['dinner']!;

    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData/weekly_template/$_selectedDay').get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        bf = data['breakfast'] ?? bf;
        lu = data['lunch'] ?? lu;
        dn = data['dinner'] ?? dn;
      }
    } catch(e) {}

    _bfCtrl.text = bf;
    _luCtrl.text = lu;
    _dnCtrl.text = dn;
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _saveDayMenu() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseDatabase.instance.ref('hostelData/weekly_template/$_selectedDay').set({
        'breakfast': _bfCtrl.text.trim(),
        'lunch': _luCtrl.text.trim(),
        'dinner': _dnCtrl.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Menu for day $_selectedDay updated!"), backgroundColor: Colors.green));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error updating menu"), backgroundColor: Colors.red));
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Edit Weekly Timetable", style: TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: const InputDecoration(labelText: "Select Day", border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text("Monday (સોમવાર)")),
                DropdownMenuItem(value: 2, child: Text("Tuesday (મંગળવાર)")),
                DropdownMenuItem(value: 3, child: Text("Wednesday (બુધવાર)")),
                DropdownMenuItem(value: 4, child: Text("Thursday (ગુરુવાર)")),
                DropdownMenuItem(value: 5, child: Text("Friday (શુક્રવાર)")),
                DropdownMenuItem(value: 6, child: Text("Saturday (શનિવાર)")),
                DropdownMenuItem(value: 7, child: Text("Sunday (રવિવાર)")),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() { _selectedDay = val; });
                  _loadDayMenu();
                }
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading) ...[
              TextField(controller: _bfCtrl, decoration: const InputDecoration(labelText: "Breakfast", border: OutlineInputBorder()), maxLines: null),
              const SizedBox(height: 12),
              TextField(controller: _luCtrl, decoration: const InputDecoration(labelText: "Lunch", border: OutlineInputBorder()), maxLines: null),
              const SizedBox(height: 12),
              TextField(controller: _dnCtrl, decoration: const InputDecoration(labelText: "Dinner", border: OutlineInputBorder()), maxLines: null),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: brandOrange, foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _saveDayMenu,
          child: const Text("Save for this Day"),
        ),
      ],
    );
  }
}
"""

# Insert widget before ViewMenuTab
idx_insert = code.find("class ViewMenuTab extends StatelessWidget {")
code = code[:idx_insert] + weekly_widget_code + "\n" + code[idx_insert:]

# Add to admin drawer
drawer_search = r'''            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text(
                'Set Menu',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSetMenuDialog();
              },
            ),'''

drawer_replace = r'''            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text(
                'Set Menu (Today)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSetMenuDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text(
                'Edit Weekly Timetable',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (context) => const WeeklyMenuEditorWidget());
              },
            ),'''

code = code.replace(drawer_search, drawer_replace)


with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Weekly Editor injected!")
