import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Change the buildMealCard to NOT take imageWidget and just show a default icon
search_str = '''  Widget _buildMealCard({
    required String icon,
    required String title,
    required String items,
    required Color color,
    Widget? imageWidget,
    bool imageOnRight = true,
  }) {
    Widget circleImage = Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
      ),
      child: ClipOval(child: imageWidget),
    );'''

replace_str = '''  Widget _buildMealCard({
    required String icon,
    required String title,
    required String items,
    required Color color,
    Widget? imageWidget,
    bool imageOnRight = true,
  }) {
    Widget circleImage = Container(
      width: 90, height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        color: color.withOpacity(0.15),
      ),
      child: Center(
        child: Icon(
          title.toLowerCase().contains("breakfast") ? Icons.free_breakfast :
          title.toLowerCase().contains("lunch") ? Icons.lunch_dining : Icons.dinner_dining,
          color: color, size: 40,
        ),
      ),
    );'''

code = code.replace(search_str, replace_str)

# Now remove the imageWidget parameter calls from the 3 cards
code = re.sub(r'imageWidget: Image.network\(.*?\),', '', code)
# Remove the URL definitions just to clean up
code = re.sub(r'String bfDemoImg = .*?;', '', code)
code = re.sub(r'String luDemoImg = .*?;', '', code)
code = re.sub(r'String dnDemoImg = .*?;', '', code)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Removed demo images and updated UI!")
