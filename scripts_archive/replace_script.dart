import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll('adminHiddenComplaints', 'globalAdminHiddenComplaints');
  content = content.replaceAll('adminLastViewedComplaints', 'globalAdminLastViewedComplaints');

  file.writeAsStringSync(content);
}
