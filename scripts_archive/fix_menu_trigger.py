import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# I will just regex out the old block
pattern = r"if \(data\['menu_trigger'\] != null \|\| data\['notices_trigger'\] != null\) \{.*?\n        \}"
text = re.sub(pattern, r"", text, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Removed legacy trigger fetch")
