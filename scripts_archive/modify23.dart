import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  int startIdx = content.indexOf('  Widget _buildHomeTab() {');
  int endIdx = content.indexOf('  Widget _buildNoticeTab() {');

  if (startIdx != -1 && endIdx != -1) {
    String newContent = '''  Widget _buildHomeTab() {
    String activeMeal = '';
    if (globalEntryB) activeMeal = 'Breakfast';
    else if (globalEntryL) activeMeal = 'Lunch';
    else if (globalEntryD) activeMeal = 'Dinner';

    DateTime now = DateTime.now();
    String key = "\${now.year}-\${now.month}-\${now.day}_\${widget.roomNo}_\${widget.name}";
    DailyRecord todayRecord = globalAttendanceMap[key] ?? DailyRecord();

    bool hasAction = false;
    String statusStr = "";
    if (activeMeal == 'Breakfast' && todayRecord.b.isNotEmpty) { hasAction = true; statusStr = todayRecord.b; }
    if (activeMeal == 'Lunch' && todayRecord.l.isNotEmpty) { hasAction = true; statusStr = todayRecord.l; }
    if (activeMeal == 'Dinner' && todayRecord.d.isNotEmpty) { hasAction = true; statusStr = todayRecord.d; }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restaurant, color: brandOrange),
                        SizedBox(width: 8),
                        Text("Mess Entry", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
                      ]
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("\${DateTime.now().day.toString().padLeft(2, '0')}/\${DateTime.now().month.toString().padLeft(2, '0')}/\${DateTime.now().year}", style: const TextStyle(color: brandOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                    )
                  ]
                ),
                const Divider(height: 32),
                if (activeMeal.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text("Mess is currently closed.\\nPlease wait for the next meal to start.", textAlign: TextAlign.center, style: TextStyle(color: brandGray, fontSize: 16)),
                    ),
                  )
                else ...[
                  Center(child: Text("🍽️ \$activeMeal Time is Active", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark))),
                  const SizedBox(height: 24),
                  if (hasAction)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: (statusStr == 'P' ? Colors.green : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusStr == 'P' ? Icons.check_circle : Icons.cancel, color: statusStr == 'P' ? Colors.green : Colors.redAccent),
                          const SizedBox(width: 8),
                          Text(statusStr == 'P' ? "Attendance marked!" : "Meal Skipped", style: TextStyle(color: statusStr == 'P' ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold))
                        ]
                      )
                    )
                  else
                    Column(
                      children: [
                        SwipeToConfirm(
                          text: "Swipe for \$activeMeal",
                          onConfirm: () {
                            setState(() {
                              globalAttendanceMap.putIfAbsent(key, () => DailyRecord());
                              if (activeMeal == 'Breakfast') globalAttendanceMap[key]!.b = 'P';
                              else if (activeMeal == 'Lunch') globalAttendanceMap[key]!.l = 'P';
                              else if (activeMeal == 'Dinner') globalAttendanceMap[key]!.d = 'P';
                            });
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(
                              mealName: activeMeal,
                              photo: widget.photo,
                              name: widget.name,
                              roomNo: widget.roomNo
                            )));
                          }
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              globalAttendanceMap.putIfAbsent(key, () => DailyRecord());
                              if (activeMeal == 'Breakfast') globalAttendanceMap[key]!.b = 'A';
                              else if (activeMeal == 'Lunch') globalAttendanceMap[key]!.l = 'A';
                              else if (activeMeal == 'Dinner') globalAttendanceMap[key]!.d = 'A';
                            });
                          },
                          icon: const Icon(Icons.no_meals, color: Colors.redAccent),
                          label: const Text("Skip Meal", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                        )
                      ]
                    )
                ]
              ],
            ),
          ),
        ),
        _buildPollCard()
      ],
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
          ]
        )
      )
    );
  }

''';
    content = content.replaceRange(startIdx, endIdx, newContent);
    file.writeAsStringSync(content);
  }
}
