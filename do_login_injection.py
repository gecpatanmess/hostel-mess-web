import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Let's find LoginScreen column and add it.
login_logo = """
                        const SizedBox(height: 30),
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
# The LoginScreen has a big Column containing the Sign In button.
# Let's look for "ElevatedButton(onPressed: _login,"
# and right after that we have the button. Then there are some SizedBoxes.
if "Developed by MDHK TENSORS" not in content:
    content = re.sub(r'(ElevatedButton\(.*?Sign In.*?\)\s*,)', r'\1' + login_logo, content, flags=re.DOTALL|re.IGNORECASE)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Added logo to login")
