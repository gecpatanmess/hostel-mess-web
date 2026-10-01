import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  String target = "class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {";
  String replacement = target + '''

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

  content = content.replaceFirst(target, replacement);

  file.writeAsStringSync(content);
}
