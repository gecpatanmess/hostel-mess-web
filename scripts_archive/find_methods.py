with open('old_main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "Widget _buildPasswordField" in line:
        print(f"_buildPasswordField at {i}")
    if "class _LoginScreenState" in line:
        print(f"_LoginScreenState at {i}")
