import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix the condition
text = re.sub(
    r"if \(globalMenuFile == null\) \{\s*try \{\s*await _dbRef\.child\('menu'\)\.remove\(\);",
    r"if (globalMenuFile == null && globalMenuUploadBytes == null) {\n      try {\n        await _dbRef.child('menu').remove();",
    text
)

# Fix the bytes and extension
text = re.sub(
    r"final bytes = await globalMenuFile!\.readAsBytes\(\);\s*final path = 'menu_\$\{DateTime\.now\(\)\.millisecondsSinceEpoch\}\.jpg';",
    r"final bytes = globalMenuUploadBytes ?? await globalMenuFile!.readAsBytes();\n      String ext = globalMenuIsPdf ? 'pdf' : 'jpg';\n      final path = 'menu_.';",
    text
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Regex replaced")
