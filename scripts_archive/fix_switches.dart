import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // Add missing boolean states to pushAll
  String pushVars = '''
    data['switches'] = {
      'globalEntryL': globalEntryL,
      'globalEntryD': globalEntryD,
      'globalPollL': globalPollL,
      'globalPollD': globalPollD,
      'globalPollDate': globalPollDate
    };
''';

  if (!content.contains("data['switches'] =")) {
    content = content.replaceFirst(
      "data['hiddenNotices'] =",
      pushVars + "\n    data['hiddenNotices'] ="
    );
  }
  
  // Add missing boolean states to listen
  String listenVars = '''
        if (data['switches'] != null) {
          globalEntryL = data['switches']['globalEntryL'] ?? false;
          globalEntryD = data['switches']['globalEntryD'] ?? false;
          globalPollL = data['switches']['globalPollL'] ?? false;
          globalPollD = data['switches']['globalPollD'] ?? false;
          globalPollDate = data['switches']['globalPollDate'] ?? "\${DateTime.now().year}-\${DateTime.now().month}-\${DateTime.now().day}";
        }
''';

  if (!content.contains("if (data['switches'] != null) {")) {
    content = content.replaceFirst(
      "if (data['hiddenNotices'] != null) {",
      listenVars + "\n        if (data['hiddenNotices'] != null) {"
    );
  }

  file.writeAsStringSync(content);
}
