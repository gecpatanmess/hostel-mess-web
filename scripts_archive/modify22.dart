import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Always show the Poll Card on Student Dashboard
  String oldCondition = '''          ),
          if (globalPollB || globalPollL || globalPollD)
            _buildPollCard()''';
  String newCondition = '''          ),
          _buildPollCard()''';
  content = content.replaceFirst(oldCondition, newCondition);

  // 2. Update Poll Card content to handle empty state
  int startIdx = content.indexOf('            const Divider(height: 32),');
  int endIdx = content.indexOf('          ]\n        )\n      )\n    );\n  }');
  
  if (startIdx != -1 && endIdx != -1) {
    String newContent = '''            const Divider(height: 32),
            
            if (!globalPollB && !globalPollL && !globalPollD)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text("No polls are currently active.", style: TextStyle(color: brandGray, fontSize: 16)),
                ),
              )
            else ...[
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
''';
    content = content.replaceRange(startIdx, endIdx, newContent);
  }

  file.writeAsStringSync(content);
}
