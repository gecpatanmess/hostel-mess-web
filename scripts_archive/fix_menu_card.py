import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Find and replace the entire ViewMenuTab class
old_class_start = "class ViewMenuTab extends StatelessWidget {"
old_class_end = "class NoticeItem {"

idx_start = code.find(old_class_start)
idx_end = code.find(old_class_end)

if idx_start == -1 or idx_end == -1:
    print("ERROR: Could not find ViewMenuTab class boundaries")
    exit(1)

new_view_menu = r'''class ViewMenuTab extends StatelessWidget {
  const ViewMenuTab({super.key});
  @override
  Widget build(BuildContext context) {
    final defaultMenu = defaultWeeklyMenu[DateTime.now().weekday] ?? defaultWeeklyMenu[DateTime.monday]!;

    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance.ref('hostelData/daily_menus/').get(),
      builder: (context, snapshot) {
        String bf = defaultMenu['breakfast']!;
        String lu = defaultMenu['lunch']!;
        String dn = defaultMenu['dinner']!;
        if (snapshot.hasData && snapshot.data!.value != null) {
          final data = Map<String, dynamic>.from(snapshot.data!.value as Map);
          bf = data['breakfast'] ?? bf;
          lu = data['lunch'] ?? lu;
          dn = data['dinner'] ?? dn;
        }

        final now = DateTime.now();
        final months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        final days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        String dateStr = "${days[now.weekday]}, ${now.day} ${months[now.month]} ${now.year}";

        // Menu image widget (the uploaded photo/pdf)
        Widget? menuImageWidget;
        if (globalMenuUploadBytes != null) {
          menuImageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(80),
            child: Image.memory(globalMenuUploadBytes!, width: 120, height: 120, fit: BoxFit.cover),
          );
        } else if (globalMenuUrl != null && globalMenuUrl!.isNotEmpty && globalMenuUrl!.startsWith('http') && !globalMenuIsPdf) {
          menuImageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(80),
            child: Image.network(globalMenuUrl!, width: 120, height: 120, fit: BoxFit.cover),
          );
        } else if (globalMenuFile != null && !kIsWeb && !globalMenuIsPdf) {
          menuImageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(80),
            child: Image.file(globalMenuFile!, width: 120, height: 120, fit: BoxFit.cover),
          );
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const Text("🍽️", style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ).createShader(bounds),
                      child: const Text(
                        "TODAY'S MENU",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Breakfast Card
              _buildMealCard(
                icon: "🌅",
                title: "BREAKFAST",
                items: bf,
                color: const Color(0xFFFF6B35),
                imageWidget: menuImageWidget,
                showImage: true,
                imageOnRight: true,
              ),
              const SizedBox(height: 16),

              // Lunch Card
              _buildMealCard(
                icon: "☀️",
                title: "LUNCH",
                items: lu,
                color: const Color(0xFF4CAF50),
                imageWidget: menuImageWidget,
                showImage: true,
                imageOnRight: false,
              ),
              const SizedBox(height: 16),

              // Dinner Card
              _buildMealCard(
                icon: "🌙",
                title: "DINNER",
                items: dn,
                color: const Color(0xFF7B68EE),
                imageWidget: menuImageWidget,
                showImage: true,
                imageOnRight: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealCard({
    required String icon,
    required String title,
    required String items,
    required Color color,
    Widget? imageWidget,
    bool showImage = false,
    bool imageOnRight = true,
  }) {
    Widget circleImage = imageWidget != null
      ? Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
          ),
          child: ClipOval(child: imageWidget),
        )
      : Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            color: color.withOpacity(0.15),
          ),
          child: Icon(Icons.restaurant, color: color, size: 40),
        );

    // Parse items by comma
    List<String> itemList = items.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    Widget textContent = Expanded(
      child: Column(
        crossAxisAlignment: imageOnRight ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...itemList.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Flexible(child: Text(item, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: imageOnRight
          ? [textContent, const SizedBox(width: 16), circleImage]
          : [circleImage, const SizedBox(width: 16), textContent],
      ),
    );
  }
}

'''

code = code[:idx_start] + new_view_menu + code[idx_end:]

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("ViewMenuTab redesigned successfully!")
