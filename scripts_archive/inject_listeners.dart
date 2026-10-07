import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  List<String> states = [
    "_StudentDashboardScreenState",
    "_AdminDashboardScreenState",
    "_AdminAttendanceScreenState"
  ];
  
  String listenerCode = '''
  void _onSync() {
    if (mounted) setState(() {});
  }
''';

  for (String state in states) {
    if (content.contains("class \$state extends State<")) {
      // Find initState
      int classIdx = content.indexOf("class \$state extends State<");
      int initIdx = content.indexOf("void initState() {", classIdx);
      
      if (initIdx != -1) {
        // Insert addListener
        content = content.replaceFirst(
          "super.initState();", 
          "super.initState();\n    globalSyncTrigger.addListener(_onSync);",
          initIdx
        );
      } else {
        // Class doesn't have initState, create it
        int bracketIdx = content.indexOf("{", classIdx);
        content = content.replaceFirst(
          "{", 
          "{\n  @override\n  void initState() {\n    super.initState();\n    globalSyncTrigger.addListener(_onSync);\n  }\n",
          bracketIdx
        );
      }
      
      // Find dispose
      int disposeIdx = content.indexOf("void dispose() {", classIdx);
      if (disposeIdx != -1) {
        content = content.replaceFirst(
          "super.dispose();", 
          "globalSyncTrigger.removeListener(_onSync);\n    super.dispose();",
          disposeIdx
        );
      } else {
        // Class doesn't have dispose, create it
        int bracketIdx = content.indexOf("{", classIdx);
        content = content.replaceFirst(
          "{", 
          "{\n  @override\n  void dispose() {\n    globalSyncTrigger.removeListener(_onSync);\n    super.dispose();\n  }\n",
          bracketIdx
        );
      }
      
      // Insert _onSync function
      int bracketIdx = content.indexOf("{", classIdx);
      content = content.replaceFirst(
        "{", 
        "{\n" + listenerCode,
        bracketIdx
      );
    }
  }
  
  file.writeAsStringSync(content);
}
