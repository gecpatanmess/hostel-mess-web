import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. RegisteredStudent class
target_rs = "class RegisteredStudent {"
repl_rs = "class RegisteredStudent {\n  String? photoUrl;"
content = content.replace(target_rs, repl_rs)

# 2. StudentComplaintsScreen constructor
target_scs = "class StudentComplaintsScreen extends StatefulWidget {\n  final String roomNo;\n  final String name;"
repl_scs = "class StudentComplaintsScreen extends StatefulWidget {\n  final String roomNo;\n  final String name;\n  final String? photoUrl;"
content = content.replace(target_scs, repl_scs)
content = content.replace("const StudentComplaintsScreen({super.key, required this.roomNo, required this.name});", "const StudentComplaintsScreen({super.key, required this.roomNo, required this.name, this.photoUrl});")

# 3. MealPassScreen constructor
target_mps = "class MealPassScreen extends StatelessWidget {\n  final String name;\n  final String roomNo;"
repl_mps = "class MealPassScreen extends StatelessWidget {\n  final String name;\n  final String roomNo;\n  final String? photoUrl;"
content = content.replace(target_mps, repl_mps)
content = content.replace("const MealPassScreen({super.key, required this.name, required this.roomNo});", "const MealPassScreen({super.key, required this.name, required this.roomNo, this.photoUrl});")

# 4. ViewMenuTab onEditMenu
target_vmt = "class ViewMenuTab extends StatefulWidget {\n  const ViewMenuTab({super.key});"
repl_vmt = "class ViewMenuTab extends StatefulWidget {\n  final VoidCallback? onEditMenu;\n  const ViewMenuTab({super.key, this.onEditMenu});"
content = content.replace(target_vmt, repl_vmt)

# AdminDashboardScreen photo vs photoUrl
# It says: 'photo' isn't initialized, and 'photoUrl' isn't a field
target_ads = "class AdminDashboardScreen extends StatefulWidget {\n  final String name;\n  final String phone;\n  final File? photo;"
repl_ads = "class AdminDashboardScreen extends StatefulWidget {\n  final String name;\n  final String phone;\n  final String? photoUrl;"
content = content.replace(target_ads, repl_ads)
content = content.replace("const AdminDashboardScreen({super.key, required this.name, required this.phone, this.photoUrl});", "const AdminDashboardScreen({super.key, required this.name, required this.phone, this.photoUrl});") # wait, the original was `this.photo`?
content = content.replace("this.photo", "this.photoUrl")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed missing fields")
