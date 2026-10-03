import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var code = file.readAsStringSync();

  if (!code.contains('bool get isValid')) {
    code = code.replaceAll(
      'email: parseStr(json[\'email\']),\n    );\n  }',
      'email: parseStr(json[\'email\']),\n    );\n  }\n\n  bool get isValid => name.isNotEmpty && roomNo.isNotEmpty;'
    );
  }

  file.writeAsStringSync(code);
  print('Done class fix!');
}
