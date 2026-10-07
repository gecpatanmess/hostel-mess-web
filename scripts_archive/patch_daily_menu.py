import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Insert Default Menu Dictionary
insert_target_1 = "Set<String> globalAdminHiddenNotices = {};"
replacement_1 = """Set<String> globalAdminHiddenNotices = {};

const Map<int, Map<String, String>> defaultWeeklyMenu = {
  DateTime.monday: {
    'breakfast': 'ચા, કોફી, પૌંઆ',
    'lunch': 'દાળ, ભાત, શાક, રોટલી',
    'dinner': 'ખીચડી, કઢી, ભાખરી, શાક',
  },
  DateTime.tuesday: {
    'breakfast': 'ચા, કોફી, ઈડલી-સાંભાર',
    'lunch': 'દાળ-બાટી, છાશ, પાપડ',
    'dinner': 'પુલાવ, કઢી, રોટલી, શાક',
  },
  DateTime.wednesday: {
    'breakfast': 'ચા, કોફી, મેદુવડા',
    'lunch': 'ભાજી-પરોઠા, છાશ, સલાડ',
    'dinner': 'વઘારેલો રોટલો, સેવ-ટમેટા, ખીચડી',
  },
  DateTime.thursday: {
    'breakfast': 'ચા, કોફી, ઉપમા',
    'lunch': 'કઢી, ભાત, શાક, રોટલી',
    'dinner': 'ઢોસા, સાંભાર, ચટણી',
  },
  DateTime.friday: {
    'breakfast': 'ચા, કોફી, થેપલા',
    'lunch': 'છોલે-ભટુરે, છાશ, અથાણું',
    'dinner': 'પાવભાજી, સલાડ',
  },
  DateTime.saturday: {
    'breakfast': 'ચા, કોફી, સમોસા',
    'lunch': 'મઠ, ભાત, શાક, પુરી',
    'dinner': 'મંચુરિયન, ફ્રાઈડ રાઈસ',
  },
  DateTime.sunday: {
    'breakfast': 'ચા, કોફી, જલેબી-ફાફડા',
    'lunch': 'પંજાબી થાળી (પનીર, નાન, દાળ મખની)',
    'dinner': 'દાળ-ઢોકળી, છાશ',
  },
};
"""
code = code.replace(insert_target_1, replacement_1)

# 2. Replace ViewMenuTab
old_view_menu_tab = """class ViewMenuTab extends StatelessWidget {
  const ViewMenuTab({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('menu').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No menu uploaded yet.", style: TextStyle(color: brandGray)));
        }
        String imgUrl = snapshot.data!.first['image_url'] ?? '';
        bool isPdf = imgUrl.toLowerCase().contains('.pdf');
        
        if (imgUrl.isEmpty) {
          return const Center(child: Text("No menu uploaded yet.", style: TextStyle(color: brandGray)));
        }

        if (isPdf) {
          return SfPdfViewer.network(imgUrl);
        } else {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                imgUrl,
                errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 50, color: brandGray),
              ),
            ),
          );
        }
      },
    );
  }
}"""

new_view_menu_tab = """class ViewMenuTab extends StatefulWidget {
  const ViewMenuTab({super.key});

  @override
  State<ViewMenuTab> createState() => _ViewMenuTabState();
}

class _ViewMenuTabState extends State<ViewMenuTab> {
  bool _showPhotoMenu = false;

  Widget _buildDailyMenuCard(String title, String items, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(items, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: brandDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showPhotoMenu) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showPhotoMenu = false),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Back to Daily Menu"),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('menu').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No photo menu uploaded.", style: TextStyle(color: brandGray)));
                }
                String imgUrl = snapshot.data!.first['image_url'] ?? '';
                bool isPdf = imgUrl.toLowerCase().contains('.pdf');
                if (imgUrl.isEmpty) {
                  return const Center(child: Text("No photo menu uploaded.", style: TextStyle(color: brandGray)));
                }
                if (isPdf) {
                  return SfPdfViewer.network(imgUrl);
                } else {
                  return InteractiveViewer(
                    child: Center(
                      child: Image.network(imgUrl, errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 50, color: brandGray)),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final weekDay = now.weekday;
    final defaultMenu = defaultWeeklyMenu[weekDay] ?? defaultWeeklyMenu[DateTime.monday]!;

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').onValue,
      builder: (context, snapshot) {
        String breakfast = defaultMenu['breakfast']!;
        String lunch = defaultMenu['lunch']!;
        String dinner = defaultMenu['dinner']!;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          breakfast = data['breakfast'] ?? breakfast;
          lunch = data['lunch'] ?? lunch;
          dinner = data['dinner'] ?? dinner;
        }

        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final dayName = days[weekDay - 1];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text("Today: $dayName", style: const TextStyle(color: brandOrange, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 20),
              _buildDailyMenuCard("Breakfast", breakfast, Icons.free_breakfast, Colors.orange),
              _buildDailyMenuCard("Lunch", lunch, Icons.lunch_dining, Colors.green),
              _buildDailyMenuCard("Dinner", dinner, Icons.dinner_dining, Colors.indigo),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showPhotoMenu = true),
                  icon: const Icon(Icons.image, color: brandGray),
                  label: const Text("View Photo / PDF Menu", style: TextStyle(color: brandGray, decoration: TextDecoration.underline)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}"""

code = code.replace(old_view_menu_tab, new_view_menu_tab)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Patched part 1")
