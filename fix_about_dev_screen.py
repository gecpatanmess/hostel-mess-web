with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import re

# Find the start and end of AboutDevelopersScreen
start_idx = code.find('class AboutDevelopersScreen extends StatelessWidget {')
end_idx = code.find('Widget _buildMemberCard(String name, String role) {')
end_class_idx = code.find('}', end_idx + 100) + 1  # end of _buildMemberCard

if start_idx != -1 and end_idx != -1:
    new_class = """class AboutDevelopersScreen extends StatelessWidget {
  const AboutDevelopersScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep slate background
      appBar: AppBar(
        title: const Text("About Developers", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Image
            Image.asset('assets/mdhk_logo.png', width: 300),
            const SizedBox(height: 48),
            // Footer
            Text(
              "Version 1.0.39",
              style: TextStyle(color: Colors.blueGrey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
"""
    code = code[:start_idx] + new_class + code[end_class_idx:]
    
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("AboutDevelopersScreen replaced!")
else:
    print("Could not find AboutDevelopersScreen")
