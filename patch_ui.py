import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add Logo at bottom of LoginScreen
login_target = """                child: isStudent ? _buildStudentPortal() : _buildAdminPortal(),
              ),
              const SizedBox(height: 24),
            ],"""

login_replacement = """                child: isStudent ? _buildStudentPortal() : _buildAdminPortal(),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    const Text("Developed by", style: TextStyle(color: brandGray, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Image.asset('assets/mdhk_logo.png', height: 28),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],"""

if login_target in code:
    code = code.replace(login_target, login_replacement)
    print("Login screen updated")
else:
    print("Could not find login target")

# 2. Add About Developers in Drawers (there are two)
drawer_target = """              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),"""

drawer_replacement = """              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline, color: brandDark),
                title: const Text(
                  'About Developers',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDevelopersScreen()));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),"""

if drawer_target in code:
    code = code.replace(drawer_target, drawer_replacement)
    print("Drawers updated")
else:
    print("Could not find drawer target")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Done phase 1")
