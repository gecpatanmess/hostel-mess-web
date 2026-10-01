import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Add globals
  String newGlobals = '''
bool globalPollB = false;
bool globalPollL = false;
bool globalPollD = false;
Map<String, Set<String>> todayPollVotes = {'B': <String>{}, 'L': <String>{}, 'D': <String>{}};
''';
  if (!content.contains('bool globalPollB = false;')) {
    content = content.replaceFirst('bool globalEntryD = false;', 'bool globalEntryD = false;\n' + newGlobals);
  }

  // 2. Remove local pollB, pollL, pollD from Admin
  String localsAdmin = '''
  // Toggle states for Mess Poll
  bool pollB = false;
  bool pollL = false;
  bool pollD = false;
''';
  content = content.replaceFirst(localsAdmin, '');

  // 3. Update Admin UI usages
  content = content.replaceAll('value: pollB,', 'value: globalPollB,');
  content = content.replaceAll('setState(() => pollB = v),', 'setState(() => globalPollB = v),');
  content = content.replaceAll('value: pollL,', 'value: globalPollL,');
  content = content.replaceAll('setState(() => pollL = v),', 'setState(() => globalPollL = v),');
  content = content.replaceAll('value: pollD,', 'value: globalPollD,');
  content = content.replaceAll('setState(() => pollD = v),', 'setState(() => globalPollD = v),');

  // 4. Inject Live Poll Results card in Admin Home Tab
  String oldAdminPollSection = '''              const Text("Mess Poll", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,''';
  
  String newAdminPollSection = '''              const Text("Mess Poll Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
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
                            label: const Text("Clear Poll", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
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
              const SizedBox(height: 16),
              Card(
                color: Colors.white,''';
  content = content.replaceFirst(oldAdminPollSection, newAdminPollSection);

  // 5. Add checkbox state to Student
  String studentStateStart = '''class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;''';
  String studentStateNew = '''class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;
  bool _pollCheckB = false;
  bool _pollCheckL = false;
  bool _pollCheckD = false;''';
  if (!content.contains('bool _pollCheckB = false;')) {
    content = content.replaceFirst(studentStateStart, studentStateNew);
  }

  // 6. Add Poll Card rendering to Student Home Tab
  String studentHomeEnd = '''        ],
      ),
    );
  }''';
  
  String studentHomeNew = '''          if (globalPollB || globalPollL || globalPollD)
            _buildPollCard()
        ],
      ),
    );
  }

  Widget _buildPollOption(String title, bool canVote, bool val, Function(bool?) onChanged) {
    if (!canVote) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough))
          ],
        ),
      );
    }
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      value: val,
      activeColor: brandOrange,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: onChanged,
    );
  }

  Widget _buildPollCard() {
    String studentKey = "\${widget.roomNo}_\${widget.name}";
    bool votedB = todayPollVotes['B']!.contains(studentKey);
    bool votedL = todayPollVotes['L']!.contains(studentKey);
    bool votedD = todayPollVotes['D']!.contains(studentKey);

    bool canVoteB = globalPollB && !votedB;
    bool canVoteL = globalPollL && !votedL;
    bool canVoteD = globalPollD && !votedD;

    bool hasPendingVote = canVoteB || canVoteL || canVoteD;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.poll, color: brandOrange),
                SizedBox(width: 8),
                Text("📝 Today's Mess Poll", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
              ]
            ),
            const Divider(height: 32),
            
            if (globalPollB) _buildPollOption("Breakfast", canVoteB, _pollCheckB, (v) => setState(() => _pollCheckB = v!)),
            if (globalPollL) _buildPollOption("Lunch", canVoteL, _pollCheckL, (v) => setState(() => _pollCheckL = v!)),
            if (globalPollD) _buildPollOption("Dinner", canVoteD, _pollCheckD, (v) => setState(() => _pollCheckD = v!)),

            if (hasPendingVote) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_pollCheckB && !_pollCheckL && !_pollCheckD) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one meal!'), backgroundColor: Colors.redAccent));
                       return;
                    }
                    setState(() {
                      if (_pollCheckB) todayPollVotes['B']!.add(studentKey);
                      if (_pollCheckL) todayPollVotes['L']!.add(studentKey);
                      if (_pollCheckD) todayPollVotes['D']!.add(studentKey);
                      _pollCheckB = false; _pollCheckL = false; _pollCheckD = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poll Submitted Successfully!'), backgroundColor: Colors.green));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: brandOrange, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Submit Vote", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                )
              )
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Thanks for voting!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                  ]
                )
              )
            ]
          ]
        )
      )
    );
  }''';
  
  if (content.contains('  Widget _buildNoticeTab() {')) {
     int insertPoint = content.indexOf('  Widget _buildNoticeTab() {');
     // We need to replace the end of _buildHomeTab safely
     // Look for "        ],\n      ),\n    );\n  }" before notice tab
     content = content.replaceFirst(studentHomeEnd, studentHomeNew);
  }

  file.writeAsStringSync(content);
}
