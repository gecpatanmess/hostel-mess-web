with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

line = text[:139872].count('\n') + 1
print("Line:", line)
