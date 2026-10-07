with open('patch_unified_auth.py', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace(
'''start_idx = text.find("Future<void> _verifyEmailStage() async {")
end_idx = text.find("Widget _buildStudentPortal() {", start_idx)

if start_idx != -1 and end_idx != -1:
    text = text[:start_idx] + unified_logic + text[end_idx:]''',
'''start_idx = text.find("  Widget _buildStudentPortal() {")
if start_idx != -1:
    text = text[:start_idx] + unified_logic + "\\n\\n" + text[start_idx:]'''
)

with open('patch_unified_auth.py', 'w', encoding='utf-8') as f:
    f.write(text)
print("Updated python script!")
