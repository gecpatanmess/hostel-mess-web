with open('patch_unified_auth.py', 'r', encoding='utf-8') as f:
    content = f.read()

import re
ui_repl = re.search(r'unified_logic = """(.*?)"""', content, re.DOTALL)
if ui_repl:
    code = ui_repl.group(1)
    print("Braces: ", code.count('{') - code.count('}'))
    print("Brackets: ", code.count('[') - code.count(']'))
    print("Parentheses: ", code.count('(') - code.count(')'))
