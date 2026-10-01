import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  String methodBody = '''  Widget _buildAdminHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("📊 Live Poll Results", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          todayPollVotes = {'B': <String>{}, 'L': <String>{}, 'D': <String>{}};
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poll data cleared!')));
                      },
                      icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                      label: const Text("Clear", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                    )
                  ]
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(children: [const Icon(Icons.free_breakfast, color: brandOrange), const SizedBox(height: 4), Text("\${todayPollVotes['B']!.length}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Text("Breakfast", style: TextStyle(color: brandGray, fontSize: 12))]),
                      Column(children: [const Icon(Icons.lunch_dining, color: brandOrange), const SizedBox(height: 4), Text("\${todayPollVotes['L']!.length}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Text("Lunch", style: TextStyle(color: brandGray, fontSize: 12))]),
                      Column(children: [const Icon(Icons.dinner_dining, color: brandOrange), const SizedBox(height: 4), Text("\${todayPollVotes['D']!.length}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Text("Dinner", style: TextStyle(color: brandGray, fontSize: 12))]),
                    ]
                  )
                )
              ]
            )
          )
        ),
      ],
    );
  }
''';

  // Completely remove existing misplaced method
  content = content.replaceAll(methodBody, '');

  // Inject correctly
  String target = '''class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;''';
  
  String replacement = target + '\n\n' + methodBody;
  
  content = content.replaceFirst(target, replacement);

  file.writeAsStringSync(content);
}
