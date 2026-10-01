import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // 1. Add globalPollDate and checkAndResetPoll
  String globals = '''
String globalPollDate = "\${DateTime.now().year}-\${DateTime.now().month}-\${DateTime.now().day}";
void checkAndResetPoll() {
  String todayStr = "\${DateTime.now().year}-\${DateTime.now().month}-\${DateTime.now().day}";
  if (globalPollDate != todayStr) {
    todayPollVotes = {'B': <String>{}, 'L': <String>{}, 'D': <String>{}};
    globalPollB = false;
    globalPollL = false;
    globalPollD = false;
    globalPollDate = todayStr;
  }
}
''';

  if (!content.contains('String globalPollDate')) {
    content = content.replaceFirst('Map<String, Set<String>> todayPollVotes', globals + '\nMap<String, Set<String>> todayPollVotes');
  }

  // 2. Call checkAndResetPoll in Student Poll Card
  String studentPollCard = '  Widget _buildPollCard() {';
  String studentPollCardNew = '  Widget _buildPollCard() {\n    checkAndResetPoll();';
  content = content.replaceFirst(studentPollCard, studentPollCardNew);

  // 3. Call checkAndResetPoll in Admin Home Tab
  String adminHomeTab = '  Widget _buildAdminHomeTab() {';
  String adminHomeTabNew = '  Widget _buildAdminHomeTab() {\n    checkAndResetPoll();';
  content = content.replaceFirst(adminHomeTab, adminHomeTabNew);

  file.writeAsStringSync(content);
}
