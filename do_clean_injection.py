import re
import os

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add AboutDevelopersScreen at the bottom
about_screen = """
class AboutDevelopersScreen extends StatelessWidget {
  const AboutDevelopersScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep slate background
      appBar: AppBar(
        title: const Text("About Developers", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            // Logo Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E293B),
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
                ]
              ),
              child: Image.asset('assets/mdhk_logo.png', height: 100),
            ),
            const SizedBox(height: 24),
            
            // Team Name
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.blueAccent, Colors.cyan],
              ).createShader(bounds),
              child: const Text(
                "MDHK TENSORS",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Innovating Hostel Management",
              style: TextStyle(fontSize: 16, color: Colors.blueGrey[300], fontStyle: FontStyle.italic),
            ),
            
            const SizedBox(height: 48),
            
            // Team Members Grid
            GridView.count(
              crossAxisCount: isWeb ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildMemberCard("Mayur", "Developer"),
                _buildMemberCard("Dax", "Developer"),
                _buildMemberCard("Himanshi", "Developer"),
                _buildMemberCard("Kunj", "Developer"),
              ],
            ),
            
            const SizedBox(height: 48),
            // Footer
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 16),
            Text(
              "Version 1.0.28",
              style: TextStyle(color: Colors.blueGrey[500], fontSize: 14),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(String name, String role) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF334155),
            child: Text(
              name[0],
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
"""
if "class AboutDevelopersScreen" not in content:
    content += "\n" + about_screen

# 2. Add button to all drawers
drawer_button = """
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Developers'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDevelopersScreen()));
              },
            ),
            const Divider(),
"""
content = re.sub(r'(ListTile\(\s*leading:\s*const\s*Icon\(Icons\.exit_to_app\),\s*title:\s*const\s*Text\(\'LogOut\'\),)', drawer_button + r'\1', content)

# 3. Add to LoginScreen Bottom
login_logo = """
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const Text('Developed by MDHK TENSORS', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Image.asset('assets/mdhk_logo.png', height: 40),
                ],
              ),
            ),
"""
if "Developed by MDHK TENSORS" not in content:
    # Just insert it right before the last closing tags of LoginScreen build
    # In LoginScreen build, there is a `return Scaffold(body: Container(...`
    # Let's insert before the `          ], // Column children` in LoginScreen if possible.
    # Alternatively we can just append it to the Column inside LoginScreen.
    pass

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Applied clean injection")
