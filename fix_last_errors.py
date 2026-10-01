with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("class AdminDashboardScreen extends StatefulWidget {\n  final String name;\n  final String phone;\n  final File? photo;",
"class AdminDashboardScreen extends StatefulWidget {\n  final String name;\n  final String phone;\n  final File? photo;\n  final String? photoUrl;")
content = content.replace("const AdminDashboardScreen({super.key, required this.name, required this.phone, this.photo});",
"const AdminDashboardScreen({super.key, required this.name, required this.phone, this.photo, this.photoUrl});")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
