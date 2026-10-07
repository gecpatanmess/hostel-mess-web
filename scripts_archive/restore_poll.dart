import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  String missingMethod = '''
  Widget _buildPollOption(
      String meal, bool canVote, bool value, void Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(
        meal,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: canVote ? brandDark : brandGray,
        ),
      ),
      value: value,
      activeColor: brandOrange,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: canVote ? onChanged : null,
    );
  }

  Widget _buildPollCard() {''';

  content = content.replaceFirst("  Widget _buildPollCard() {", missingMethod);
  
  file.writeAsStringSync(content);
}
