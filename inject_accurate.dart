import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  String studentTarget = "class _StudentDashboardScreenState extends State<StudentDashboardScreen> {";
  String studentReplacement = studentTarget + '''

  @override
  void initState() {
    super.initState();
    globalSyncTrigger.addListener(_onSync);
  }

  @override
  void dispose() {
    globalSyncTrigger.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }
''';

  content = content.replaceFirst(studentTarget, studentReplacement);

  String adminTarget = "class _AdminDashboardScreenState extends State<AdminDashboardScreen> {";
  String adminReplacement = adminTarget + '''

  @override
  void initState() {
    super.initState();
    globalSyncTrigger.addListener(_onSync);
  }

  @override
  void dispose() {
    globalSyncTrigger.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }
''';

  content = content.replaceFirst(adminTarget, adminReplacement);

  file.writeAsStringSync(content);
}
