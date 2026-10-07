import re
from collections import defaultdict

# 1. Collect all valid words from main.dart.bak
valid_words = set()
with open('lib/main.dart.bak', 'r', encoding='utf-8') as f:
    text = f.read()
    words = re.findall(r'[a-zA-Z_]+', text)
    valid_words.update(words)

# Also collect from all patch*.py and refactor*.py
import glob
for file in glob.glob('patch*.py') + glob.glob('refactor*.py'):
    with open(file, 'r', encoding='utf-8') as f:
        text = f.read()
        words = re.findall(r'[a-zA-Z_]+', text)
        valid_words.update(words)

# 2. Build mapping of broken_word -> valid_word
# Only for words that contain 'o'
broken_to_valid = defaultdict(set)
for w in valid_words:
    if 'o' in w:
        broken = w.replace('o', '')
        broken_to_valid[broken].add(w)

# See if there are collisions
collisions = {k: v for k, v in broken_to_valid.items() if len(v) > 1}
print(f"Total valid words with 'o': {len([w for w in valid_words if 'o' in w])}")
print(f"Total collisions: {len(collisions)}")
# print a few collisions
for i, (k, v) in enumerate(collisions.items()):
    if i < 10:
        print(f"{k} -> {v}")
