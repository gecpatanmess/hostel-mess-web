import glob
import ast

def get_strings_from_py(filepath):
    strings = []
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    try:
        tree = ast.parse(content)
    except Exception:
        # If AST parsing fails, just regex for triple quotes
        import re
        # Find all """...""" and '''...'''
        strs = re.findall(r'"""(.*?)"""', content, re.DOTALL)
        strs += re.findall(r"'''(.*?)'''", content, re.DOTALL)
        return strs
    
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and isinstance(node.value, ast.Constant):
                    if isinstance(node.value.value, str):
                        strings.append(node.value.value)
    return strings

all_valid_strings = []
for file in glob.glob('*.py'):
    if file in ['fix_encoding.py', 'test_restore.py', 'test_overlap.py']: continue
    all_valid_strings.extend(get_strings_from_py(file))

# Filter out very short strings
all_valid_strings = [s for s in all_valid_strings if len(s) > 20]
print(f"Extracted {len(all_valid_strings)} valid strings from scripts.")

# Now, we also have main.dart.bak. We can't do exact block replacement for it easily unless we find chunks.
