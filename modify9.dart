import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Add dart:async
  if (!content.contains("import 'dart:async';")) {
    content = content.replaceFirst("import 'dart:io';", "import 'dart:io';\nimport 'dart:async';");
  }

  // 2. Add globals
  String newGlobals = '''
bool globalEntryB = false;
bool globalEntryL = false;
bool globalEntryD = false;
Set<String> globalSwipedStudents = {};
''';
  if (!content.contains('bool globalEntryB = false;')) {
    content = content.replaceFirst('File? globalMenuFile;', newGlobals + '\nFile? globalMenuFile;');
  }

  // 3. Remove local entry switches in Admin
  String locals = '''
  // Toggle states for Mess Entry
  bool entryB = false;
  bool entryL = false;
  bool entryD = false;
''';
  content = content.replaceAll(locals, '');

  // Replace usages in Admin Dashboard
  content = content.replaceAll('value: entryB,', 'value: globalEntryB,');
  content = content.replaceAll('setState(() => entryB = v)', 'setState(() => globalEntryB = v)');
  content = content.replaceAll('value: entryL,', 'value: globalEntryL,');
  content = content.replaceAll('setState(() => entryL = v)', 'setState(() => globalEntryL = v)');
  content = content.replaceAll('value: entryD,', 'value: globalEntryD,');
  content = content.replaceAll('setState(() => entryD = v)', 'setState(() => globalEntryD = v)');

  // 4. Update Student Home Content
  String oldHomeContent = '''const Center(child: Text("Home Content", style: TextStyle(color: brandGray)))''';
  String newHomeContent = '''_buildHomeTab()''';
  content = content.replaceFirst(oldHomeContent, newHomeContent);

  // 5. Add _buildHomeTab to _StudentDashboardScreenState
  String buildHomeTabMethod = '''
  Widget _buildHomeTab() {
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
  }

  Widget _buildNoticeTab() {''';

  content = content.replaceFirst('  Widget _buildNoticeTab() {', buildHomeTabMethod);

  // 6. Add new Widgets at the end of the file
  String additionalWidgets = '''
class SwipeToConfirm extends StatefulWidget {
  final VoidCallback onConfirm;
  final String text;
  const SwipeToConfirm({super.key, required this.onConfirm, required this.text});

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  final double _height = 60.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxDrag = constraints.maxWidth - _height;
      return Container(
        height: _height,
        decoration: BoxDecoration(
          color: brandInputBg,
          borderRadius: BorderRadius.circular(_height / 2),
          border: Border.all(color: brandOrange.withOpacity(0.5)),
        ),
        child: Stack(
          children: [
            Center(child: Text(widget.text, style: const TextStyle(fontWeight: FontWeight.w600, color: brandGray))),
            Positioned(
              left: _dragPosition,
              child: GestureDetector(
                onPanUpdate: (details) {
                  if (_isConfirmed) return;
                  setState(() {
                    _dragPosition += details.delta.dx;
                    if (_dragPosition < 0) _dragPosition = 0;
                    if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                  });
                },
                onPanEnd: (details) {
                  if (_isConfirmed) return;
                  if (_dragPosition > maxDrag * 0.8) {
                    setState(() {
                      _dragPosition = maxDrag;
                      _isConfirmed = true;
                    });
                    widget.onConfirm();
                  } else {
                    setState(() {
                      _dragPosition = 0; // snap back
                    });
                  }
                },
                child: Container(
                  width: _height,
                  height: _height,
                  decoration: const BoxDecoration(
                    color: brandOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class MealPassScreen extends StatefulWidget {
  final String mealName;
  final File photo;
  final String name;
  final String roomNo;
  const MealPassScreen({super.key, required this.mealName, required this.photo, required this.name, required this.roomNo});
  @override
  State<MealPassScreen> createState() => _MealPassScreenState();
}

class _MealPassScreenState extends State<MealPassScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() { _now = DateTime.now(); });
    });
  }
  @override
  void dispose() { 
    _timer.cancel(); 
    super.dispose(); 
  }

  String _formatTime(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    int hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12;
    return "\${pad(hour12)}:\${pad(dt.minute)}:\${pad(dt.second)} \$period";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade600,
      appBar: AppBar(
         backgroundColor: Colors.transparent, 
         elevation: 0,
         leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 100),
            const SizedBox(height: 16),
            Text("\${widget.mealName.toUpperCase()} APPROVED", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: CircleAvatar(radius: 60, backgroundImage: FileImage(widget.photo)),
            ),
            const SizedBox(height: 16),
            Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text("Room: \${widget.roomNo}", style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(30)),
              child: Text(_formatTime(_now), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
            )
          ]
        )
      )
    );
  }
}
''';

  if (!content.contains('class SwipeToConfirm')) {
    content = content + '\n' + additionalWidgets;
  }

  file.writeAsStringSync(content);
}
