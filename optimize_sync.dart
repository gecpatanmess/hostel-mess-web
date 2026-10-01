import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // Add variables
  content = content.replaceFirst(
      "static int _lastHash = 0;",
      "static int _lastHash = 0;\n  static String _lastMenuPath = \"\";\n  static String _lastDownloadedMenuBase64 = \"\";"
  );

  // Fix pushAll()
  String oldMenuPush = '''
    // Menu File
    String menuBase64 = "";
    if (globalMenuFile != null && globalMenuFile!.existsSync() && !kIsWeb) {
      try {
        menuBase64 = base64Encode(await globalMenuFile!.readAsBytes());
      } catch(e){}
    }
    data['menu'] = {
      'isPdf': globalMenuIsPdf,
      'fileBase64': menuBase64
    };
''';

  String newMenuPush = '''
    // Menu File (Only upload if changed)
    String currentMenuPath = globalMenuFile?.path ?? "";
    if (currentMenuPath != _lastMenuPath) {
      String menuBase64 = "";
      if (globalMenuFile != null && globalMenuFile!.existsSync() && !kIsWeb) {
        try {
          menuBase64 = base64Encode(await globalMenuFile!.readAsBytes());
        } catch(e){}
      }
      data['menu'] = {
        'isPdf': globalMenuIsPdf,
        'fileBase64': menuBase64
      };
      _lastMenuPath = currentMenuPath;
    }
''';

  content = content.replaceFirst(oldMenuPush, newMenuPush);

  // Use update instead of set
  content = content.replaceFirst("await _dbRef.set(data);", "await _dbRef.update(data);");
  content = content.replaceFirst("await _dbRef.set(dataToPush);", "await _dbRef.update(dataToPush);"); // just in case

  // Fix listen()
  String oldMenuListen = '''
        if (data['menu'] != null) {
          globalMenuIsPdf = data['menu']['isPdf'] ?? false;
          String menuBase64 = data['menu']['fileBase64'] ?? '';
          if (menuBase64.isNotEmpty && !kIsWeb) {
            final dir = await getApplicationDocumentsDirectory();
            String ext = globalMenuIsPdf ? 'pdf' : 'jpg';
            File mFile = File('\${dir.path}/mess_menu_\${DateTime.now().millisecondsSinceEpoch}.\$ext');
            await mFile.writeAsBytes(base64Decode(menuBase64));
            globalMenuFile = mFile;
          } else {
            globalMenuFile = null;
          }
        }
''';

  String newMenuListen = '''
        if (data['menu'] != null) {
          globalMenuIsPdf = data['menu']['isPdf'] ?? false;
          String menuBase64 = data['menu']['fileBase64'] ?? '';
          if (menuBase64 != _lastDownloadedMenuBase64) {
            _lastDownloadedMenuBase64 = menuBase64;
            if (menuBase64.isNotEmpty && !kIsWeb) {
              final dir = await getApplicationDocumentsDirectory();
              String ext = globalMenuIsPdf ? 'pdf' : 'jpg';
              File mFile = File('\${dir.path}/mess_menu_\${DateTime.now().millisecondsSinceEpoch}.\$ext');
              await mFile.writeAsBytes(base64Decode(menuBase64));
              globalMenuFile = mFile;
              _lastMenuPath = mFile.path;
            } else {
              globalMenuFile = null;
              _lastMenuPath = "";
            }
          }
        }
''';

  content = content.replaceFirst(oldMenuListen, newMenuListen);

  file.writeAsStringSync(content);
}
