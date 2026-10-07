import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // A generic way to inject ValueListenableBuilder around Scaffolds in specific states
  List<String> statesToWrap = [
    "_StudentDashboardScreenState",
    "_AdminDashboardScreenState",
    "_AdminAttendanceScreenState"
  ];
  
  for (String state in statesToWrap) {
    if (content.contains("class \$state extends State<")) {
      int classIdx = content.indexOf("class \$state extends State<");
      int buildIdx = content.indexOf("Widget build(BuildContext context) {", classIdx);
      if (buildIdx != -1) {
        int scaffoldIdx = content.indexOf("return Scaffold(", buildIdx);
        if (scaffoldIdx != -1 && scaffoldIdx < content.indexOf("class ", buildIdx + 20) || !content.contains("class ", buildIdx + 20)) {
          // Check if already wrapped
          if (!content.substring(buildIdx, scaffoldIdx).contains("ValueListenableBuilder")) {
            content = content.replaceFirst(
              "return Scaffold(",
              "return ValueListenableBuilder<int>(\n      valueListenable: globalSyncTrigger,\n      builder: (context, syncVal, _) {\n        return Scaffold(",
              scaffoldIdx - 5
            );
            
            // Now we need to find the end of the build method to add the closing braces
            // We can just add it before the end of the class. But parsing bracket matching is hard.
            // Let's do a simple regex for the final brace of the build method.
            // But a much easier way: Just find the next class definition and insert before it. 
            // Better: find the end of the file or next class and look for the last '}' before it.
          }
        }
      }
    }
  }
}
