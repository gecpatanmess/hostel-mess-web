import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

state_start = text.find('class _LoginScreenState extends State<LoginScreen> {')
brackets = 0
in_string = False
escape = False
for i in range(state_start, len(text)):
    c = text[i]
    if escape:
        escape = False
        continue
    if c == '\\':
        escape = True
        continue
    if c == '"' or c == "'":
        if in_string == c:
            in_string = False
        elif not in_string:
            in_string = c
        continue
    if not in_string:
        if c == '{':
            brackets += 1
        elif c == '}':
            brackets -= 1
            if brackets == 0:
                print("State closes at index", i)
                line = text[:i].count('\n') + 1
                print("State closes at line", line)
                print("Context:", text[i-50:i+50])
                break
