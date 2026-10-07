with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

in_state = False
brackets = 0
state_end = -1
for i, line in enumerate(lines):
    if "class _LoginScreenState" in line:
        in_state = True
    if in_state:
        brackets += line.count('{')
        brackets -= line.count('}')
        if brackets == 0:
            state_end = i
            break
print(f"State ends at line {state_end}")
