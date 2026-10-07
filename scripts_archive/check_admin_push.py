with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
# Find the admin creation block (Instance 3) and check if pushAdmins is called after
idx = content.find("globalAdmins.add(AdminUser(_newAdminMobileCtrl.text, hashPassword(_newAdminPinCtrl.text)))")
if idx != -1:
    print(content[idx:idx+800])
