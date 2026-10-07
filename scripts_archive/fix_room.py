import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace(
    'Text("Room: ", style: const TextStyle(fontSize: 14, color: brandGray)),',
    'Text("Room: ", style: const TextStyle(fontSize: 14, color: brandGray)),'
)

text = text.replace(
'''                    ] else if (_isAdminFlow || hasSavedAdmin) ...[
                      const Text("Admin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
                    ] else ...[''',
'''                    ] else if (_isAdminFlow || hasSavedAdmin) ...[
                      const Text("Admin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
                    ] else ...[
                      Text(
                        hasSavedStudent ? "Room: " : "",
                        style: const TextStyle(fontSize: 14, color: brandGray),
                      ),'''
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Room bug fixed.")
