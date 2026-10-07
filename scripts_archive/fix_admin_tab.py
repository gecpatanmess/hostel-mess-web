with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import re

# Insert the email controller
code = code.replace(
    "final TextEditingController _newAdminPinCtrl = TextEditingController();\n  final TextEditingController _changeAdminPinCtrl = TextEditingController();",
    "final TextEditingController _newAdminPinCtrl = TextEditingController();\n  final TextEditingController _changeAdminPinCtrl = TextEditingController();\n  final TextEditingController _newAdminEmailCtrl = TextEditingController();"
)

# Extract and replace _buildAdminsTab
start_str = "  Widget _buildAdminsTab() {"
end_str = "  Widget _buildAdminHomeTab() {"

start_idx = code.find(start_str)
end_idx = code.find(end_str)

if start_idx != -1 and end_idx != -1:
    new_tab = """  Widget _buildAdminsTab() {
    return SingleChildScrollView(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Create New Admin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 20),
          TextField(
            controller: _newAdminMobileCtrl,
            decoration: InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            keyboardType: TextInputType.phone,
            maxLength: 10,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newAdminEmailCtrl,
            decoration: InputDecoration(labelText: "Email ID", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newAdminPinCtrl,
            decoration: InputDecoration(labelText: "8-character Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            maxLength: 8,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (_newAdminMobileCtrl.text.length == 10 && _newAdminPinCtrl.text.length == 8 && _newAdminEmailCtrl.text.contains('@')) {
                  setState(() {
                    globalAdmins.add(AdminUser(_newAdminMobileCtrl.text, hashPassword(_newAdminPinCtrl.text), email: _newAdminEmailCtrl.text.trim()));
                  });
                  final prefs = await SharedPreferences.getInstance();
                  List<String> adminStrings = globalAdmins.map((a) => jsonEncode(a.toJson())).toList();
                  await prefs.setStringList('globalAdmins', adminStrings);
                  SyncService.pushAdmins();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin created successfully!"), backgroundColor: Colors.green));
                  _newAdminMobileCtrl.clear();
                  _newAdminPinCtrl.clear();
                  _newAdminEmailCtrl.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter valid mobile, email and password."), backgroundColor: Colors.red));
                }
              },
              child: const Text("Create Admin", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ));
  }

"""
    code = code[:start_idx] + new_tab + code[end_idx:]
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Replaced _buildAdminsTab successfully!")
else:
    print("Could not find _buildAdminsTab bounds.")
