import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // Add globals
  String globals = '''
Set<String> globalStudentHiddenNotices = {};
DateTime globalStudentLastViewedNotices = DateTime(2000);
''';
  content = content.replaceFirst('Set<String> globalAdminHiddenComplaints = {};', globals + 'Set<String> globalAdminHiddenComplaints = {};');

  // Remove locals
  content = content.replaceFirst('  Set<String> hiddenNoticeIds = {};\n  DateTime lastViewedNoticeTime = DateTime(2000);', '');

  // Replace usages
  content = content.replaceAll('hiddenNoticeIds', 'globalStudentHiddenNotices');
  content = content.replaceAll('lastViewedNoticeTime', 'globalStudentLastViewedNotices');

  file.writeAsStringSync(content);
}
