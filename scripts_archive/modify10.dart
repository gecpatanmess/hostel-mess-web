import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  String oldHomeTab = '''  Widget _buildHomeTab() {
    String activeMeal = '';
    if (globalEntryB) activeMeal = 'Breakfast';
    else if (globalEntryL) activeMeal = 'Lunch';
    else if (globalEntryD) activeMeal = 'Dinner';

    if (activeMeal.isEmpty) {
      return const Center(child: Text("No meal is active currently.", style: TextStyle(color: brandGray)));
    }

    String swipeKey = "\$activeMeal-\${widget.name}";
    bool hasSwiped = globalSwipedStudents.contains(swipeKey);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text("🍽️ \$activeMeal Time is Active", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
                  const SizedBox(height: 24),
                  if (hasSwiped)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text("Attendance marked!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                        ]
                      )
                    )
                  else
                    SwipeToConfirm(
                      text: "Swipe for \$activeMeal",
                      onConfirm: () {
                        setState(() {
                          globalSwipedStudents.add(swipeKey);
                        });
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(
                          mealName: activeMeal,
                          photo: widget.photo,
                          name: widget.name,
                          roomNo: widget.roomNo
                        )));
                      }
                    )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }''';

  String newHomeTab = '''  Widget _buildHomeTab() {
    String activeMeal = '';
    if (globalEntryB) activeMeal = 'Breakfast';
    else if (globalEntryL) activeMeal = 'Lunch';
    else if (globalEntryD) activeMeal = 'Dinner';

    String swipeKey = "\$activeMeal-\${widget.name}";
    bool hasSwiped = activeMeal.isNotEmpty && globalSwipedStudents.contains(swipeKey);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
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
                  const Row(
                    children: [
                      Icon(Icons.restaurant, color: brandOrange),
                      SizedBox(width: 8),
                      Text("Mess Entry", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
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
                    if (hasSwiped)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Attendance marked!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                          ]
                        )
                      )
                    else
                      SwipeToConfirm(
                        text: "Swipe for \$activeMeal",
                        onConfirm: () {
                          setState(() {
                            globalSwipedStudents.add(swipeKey);
                          });
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MealPassScreen(
                            mealName: activeMeal,
                            photo: widget.photo,
                            name: widget.name,
                            roomNo: widget.roomNo
                          )));
                        }
                      )
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }''';

  content = content.replaceFirst(oldHomeTab, newHomeTab);
  file.writeAsStringSync(content);
}
