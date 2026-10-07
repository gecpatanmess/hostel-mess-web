import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Fix brandLightOrange
text = text.replace('color: brandLightOrange,', 'color: const Color(0xFFFDE9D2),')

# 2. Fix cropStyle
text = text.replace('cropStyle: CropStyle.circle,', '')

# 3. Remove the second _handleUnifiedAction
idx1 = text.find('  Future<void> _handleUnifiedAction() async {')
idx2 = text.find('  Future<void> _handleUnifiedAction() async {', idx1 + 10)

if idx2 != -1:
    # Find the end of the SECOND _handleUnifiedAction (which goes up to Widget _buildStudentPortal)
    idx_end = text.find('  Widget _buildStudentPortal() {', idx2)
    if idx_end != -1:
        text = text[:idx2] + text[idx_end:]
        print("Removed second _handleUnifiedAction")
    else:
        print("Could not find end of second _handleUnifiedAction")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

