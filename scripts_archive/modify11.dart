import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // Change 1: Add date to the Mess Entry card header
  String oldRow = '''                  const Row(
                    children: [
                      Icon(Icons.restaurant, color: brandOrange),
                      SizedBox(width: 8),
                      Text("Mess Entry", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
                    ]
                  ),''';

  String newRow = '''                  Row(
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
                  ),''';

  content = content.replaceFirst(oldRow, newRow);

  // Change 2: Add date to the green Meal Pass screen
  String oldFormatTime = '''  String _formatTime(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    int hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12;
    return "\${pad(hour12)}:\${pad(dt.minute)}:\${pad(dt.second)} \$period";
  }''';

  String newFormatTime = '''  String _formatTime(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    int hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12;
    return "\${pad(dt.day)}/\${pad(dt.month)}/\${dt.year} | \${pad(hour12)}:\${pad(dt.minute)}:\${pad(dt.second)} \$period";
  }''';

  content = content.replaceFirst(oldFormatTime, newFormatTime);

  // Just to be extra safe, if oldFormatTime wasn't found due to spacing:
  if (!content.contains(newFormatTime)) {
     content = content.replaceFirst('return "\${pad(hour12)}:\${pad(dt.minute)}:\${pad(dt.second)} \$period";', 'return "\${pad(dt.day)}/\${pad(dt.month)}/\${dt.year} | \${pad(hour12)}:\${pad(dt.minute)}:\${pad(dt.second)} \$period";');
  }

  file.writeAsStringSync(content);
}
