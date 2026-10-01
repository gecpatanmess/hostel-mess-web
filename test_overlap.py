import re
from collections import defaultdict

valid_words = set()
with open('lib/main.dart.bak', 'r', encoding='utf-8') as f:
    valid_words.update(re.findall(r'[a-zA-Z_]+', f.read()))

import glob
for file in glob.glob('patch*.py') + glob.glob('refactor*.py'):
    with open(file, 'r', encoding='utf-8') as f:
        valid_words.update(re.findall(r'[a-zA-Z_]+', f.read()))

# words that do not contain 'o'
no_o_words = {w for w in valid_words if 'o' not in w}

overlap = []
for w in valid_words:
    if 'o' in w:
        broken = w.replace('o', '')
        if broken in no_o_words:
            overlap.append((broken, w))

print(f"Total overlaps: {len(overlap)}")
for b, w in overlap:
    print(f"{b} -> {w}")
