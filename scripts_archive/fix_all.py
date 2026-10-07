import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix 1: ViewMenuTab Text
view_menu_old = '''        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandOrange)),
              const Divider(),
              Text("?? Breakfast: ", style: const TextStyle(fontSize: 15, height: 1.5, color: brandDark)),
              Text("?? Lunch: ", style: const TextStyle(fontSize: 15, height: 1.5, color: brandDark)),
              Text("?? Dinner: ", style: const TextStyle(fontSize: 15, height: 1.5, color: brandDark)),
            ],
          ),
        );'''
        
view_menu_new = '''        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandOrange)),
              const Divider(),
              Text("?? Breakfast: " + bf, style: const TextStyle(fontSize: 15, height: 1.5, color: brandDark)),
              Text("?? Lunch: " + lu, style: const TextStyle(fontSize: 15, height: 1.5, color: brandDark)),
              Text("?? Dinner: " + dn, style: const TextStyle(fontSize: 15, height: 1.5, color: brandDark)),
            ],
          ),
        );'''

# Also fix formattedDate logic
fd_old = '''          String formattedDate = " ,  - ";'''
fd_new = '''          String formattedDate = "\ \, \ - \";'''

code = code.replace(view_menu_old, view_menu_new)
code = code.replace(fd_old, fd_new)


# Fix 2: Add SyncService.pushAdmins() when creating admin
admin_create_old = '''                  if (_newAdminMobileCtrl.text.length == 10 && _newAdminPinCtrl.text.length == 8) {
                    setState(() {
                      globalAdmins.add(AdminUser(_newAdminMobileCtrl.text, hashPassword(_newAdminPinCtrl.text)));
                    });
                    final prefs = await SharedPreferences.getInstance();
                    List<String> adminStrings = globalAdmins.map((a) => jsonEncode(a.toJson())).toList();
                    await prefs.setStringList('globalAdmins', adminStrings);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin created successfully!"), backgroundColor: Colors.green));'''

admin_create_new = '''                  if (_newAdminMobileCtrl.text.length == 10 && _newAdminPinCtrl.text.length == 8) {
                    setState(() {
                      globalAdmins.add(AdminUser(_newAdminMobileCtrl.text, hashPassword(_newAdminPinCtrl.text)));
                    });
                    SyncService.pushAdmins();
                    final prefs = await SharedPreferences.getInstance();
                    List<String> adminStrings = globalAdmins.map((a) => jsonEncode(a.toJson())).toList();
                    await prefs.setStringList('globalAdmins', adminStrings);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin created successfully!"), backgroundColor: Colors.green));'''
code = code.replace(admin_create_old, admin_create_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Applied fix 1 and 2")
