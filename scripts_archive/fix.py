import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's see the broken block
lines = text.split('\n')
for i in range(2850, min(2870, len(lines))):
    print(f"{i+1}: {lines[i]}")
