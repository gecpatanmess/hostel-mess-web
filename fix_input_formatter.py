import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

input_def = '''  Widget _buildInputField({
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: brandDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration('''

input_def_fixed = '''  Widget _buildInputField({
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    TextEditingController? controller,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: brandDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration('''
          
code = code.replace(input_def, input_def_fixed)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("inputFormatters added to _buildInputField")
