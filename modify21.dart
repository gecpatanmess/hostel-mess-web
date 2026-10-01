import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  String oldStr = '''          )
          if (globalPollB || globalPollL || globalPollD)''';

  String newStr = '''          ),
          if (globalPollB || globalPollL || globalPollD)''';

  content = content.replaceFirst(oldStr, newStr);

  file.writeAsStringSync(content);
}
