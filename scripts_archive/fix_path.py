import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target = "final path = 'menu_.';"
new_target = "final path = 'menu_${globalHostelMode}_${DateTime.now().millisecondsSinceEpoch}.$ext';"

if target in text:
    text = text.replace(target, new_target)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS: Fixed path logic")
else:
    print("FAIL: Target not found")
