import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Rewrite _buildHomeTab
  String oldHomeTab = '''  Widget _buildHomeTab() {
    String activeMeal = '';
    if (globalEntryL)
      activeMeal = 'Lunch';
    else if (globalEntryD)
      activeMeal = 'Dinner';

    DateTime now = DateTime.now();
    String key =
        "\${now.year}-\${now.month}-\${now.day}_\${widget.roomNo}_\${widget.name}";
    DailyRecord todayRecord = globalAttendanceMap[key] ?? DailyRecord();

    bool hasAction = false;
    String statusStr = "";

    if (activeMeal == 'Lunch' && todayRecord.l.isNotEmpty) {
      hasAction = true;
      statusStr = todayRecord.l;
    }
    if (activeMeal == 'Dinner' && todayRecord.d.isNotEmpty) {
      hasAction = true;
      statusStr = todayRecord.d;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        Text(
                          "Mess Entry",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: brandDark,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: brandOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "\${DateTime.now().day.toString().padLeft(2, '0')}/\${DateTime.now().month.toString().padLeft(2, '0')}/\${DateTime.now().year}",
                        style: const TextStyle(
                          color: brandOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                if (activeMeal.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        "Mess is currently closed.\\nPlease wait for the next meal to start.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: brandGray, fontSize: 16),
                      ),
                    ),
                  )
                else ...[
                  Center(
                    child: Text(
                      "🍽️ \$activeMeal Time is Active",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (hasAction)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            (statusStr == 'P' ? Colors.green : Colors.redAccent)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            statusStr == 'P'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: statusStr == 'P'
                                ? Colors.green
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusStr == 'P'
                                ? "Attendance marked!"
                                : "Meal Skipped",
                            style: TextStyle(
                              color: statusStr == 'P'
                                  ? Colors.green
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        SwipeToConfirm(
                          text: "Swipe for \$activeMeal",
                          onConfirm: () {
                            setState(() {
                              globalAttendanceMap.putIfAbsent(
                                key,
                                () => DailyRecord(),
                              );
                              if (activeMeal == 'Lunch')
                                globalAttendanceMap[key]!.l = 'P';
                              else if (activeMeal == 'Dinner')
                                globalAttendanceMap[key]!.d = 'P';
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MealPassScreen(
                                  mealName: activeMeal,
                                  photo: widget.photo,
                                  name: widget.name,
                                  roomNo: widget.roomNo,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              globalAttendanceMap.putIfAbsent(
                                key,
                                () => DailyRecord(),
                              );
                              if (activeMeal == 'Lunch')
                                globalAttendanceMap[key]!.l = 'A';
                              else if (activeMeal == 'Dinner')
                                globalAttendanceMap[key]!.d = 'A';
                            });
                          },
                          icon: const Icon(Icons.cancel, color: Colors.redAccent),
                          label: const Text(
                            "Skip Meal",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
        _buildPollCard(),
      ],
    );
  }''';

  String newHomeTab = '''  Widget _buildHomeTab() {
    DateTime now = DateTime.now();
    String key = "\${now.year}-\${now.month}-\${now.day}_\${widget.roomNo}_\${widget.name}";
    DailyRecord todayRecord = globalAttendanceMap[key] ?? DailyRecord();

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
                        Text("Today's Attendance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("\${now.day.toString().padLeft(2, '0')}/\${now.month.toString().padLeft(2, '0')}/\${now.year}", style: const TextStyle(color: brandOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const Divider(height: 32),
                
                // LUNCH SECTION
                const Text("Lunch", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                const SizedBox(height: 8),
                if (todayRecord.l.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: (todayRecord.l == 'P' ? Colors.green : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(todayRecord.l == 'P' ? Icons.check_circle : Icons.cancel, color: todayRecord.l == 'P' ? Colors.green : Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(todayRecord.l == 'P' ? "Attendance marked! (P)" : "Meal Skipped (A)", style: TextStyle(color: todayRecord.l == 'P' ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else if (globalEntryL)
                  Column(
                    children: [
                      SwipeToConfirm(
                        text: "Swipe for Lunch",
                        onConfirm: () {
                          setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.l = 'P'; });
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(mealName: 'Lunch', photo: widget.photo, name: widget.name, roomNo: widget.roomNo)));
                        },
                      ),
                      TextButton.icon(
                        onPressed: () { setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.l = 'A'; }); },
                        icon: const Icon(Icons.cancel, color: Colors.redAccent), label: const Text("Skip Meal", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                else
                  const Text("Waiting for Admin to open Lunch Entry...", style: TextStyle(color: brandGray, fontStyle: FontStyle.italic)),

                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 24),

                // DINNER SECTION
                const Text("Dinner", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                const SizedBox(height: 8),
                if (todayRecord.d.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: (todayRecord.d == 'P' ? Colors.green : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(todayRecord.d == 'P' ? Icons.check_circle : Icons.cancel, color: todayRecord.d == 'P' ? Colors.green : Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(todayRecord.d == 'P' ? "Attendance marked! (P)" : "Meal Skipped (A)", style: TextStyle(color: todayRecord.d == 'P' ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else if (globalEntryD)
                  Column(
                    children: [
                      SwipeToConfirm(
                        text: "Swipe for Dinner",
                        onConfirm: () {
                          setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.d = 'P'; });
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(mealName: 'Dinner', photo: widget.photo, name: widget.name, roomNo: widget.roomNo)));
                        },
                      ),
                      TextButton.icon(
                        onPressed: () { setState(() { globalAttendanceMap.putIfAbsent(key, () => DailyRecord()); globalAttendanceMap[key]!.d = 'A'; }); },
                        icon: const Icon(Icons.cancel, color: Colors.redAccent), label: const Text("Skip Meal", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                else
                  const Text("Waiting for Admin to open Dinner Entry...", style: TextStyle(color: brandGray, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ),
        _buildPollCard(),
      ],
    );
  }''';

  // 2. Remove checkAndResetPoll usages
  content = content.replaceFirst("checkAndResetPoll();\n    String studentKey", "String studentKey");
  content = content.replaceFirst("checkAndResetPoll();\n    return ListView", "return ListView");

  // 3. Optional: make checkAndResetPoll robust in SyncService if we want, but for now we removed it from UI build.
  // Wait, let's fix the string replacement first
  // The exact string for checkAndResetPoll in _buildPollCard is:
  // "checkAndResetPoll();\n    String studentKey = \"\${widget.roomNo}_\${widget.name}\";"
  // Let's replace the whole oldHomeTab
  // Also we need to make sure the emojis encode properly. I will just replace the exact text.
  
  if (content.contains("Widget _buildHomeTab() {")) {
    int start = content.indexOf("Widget _buildHomeTab() {");
    int end = content.indexOf("  Widget _buildPollCard() {");
    if (start != -1 && end != -1) {
      content = content.replaceRange(start, end, newHomeTab + "\\n\\n");
    }
  }
  
  // Find checkAndResetPoll calls and remove them
  content = content.replaceAll("checkAndResetPoll();", "");

  file.writeAsStringSync(content);
}
