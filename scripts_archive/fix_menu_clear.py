import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target_menu = '''        if (data['menu'] != null) {
          globalMenuIsPdf = data['menu']['isPdf'] ?? false;
          String menuBase64 = data['menu']['fileBase64'] ?? '';
          if (menuBase64 != _lastDownloadedMenuBase64) {
            _lastDownloadedMenuBase64 = menuBase64;
            if (menuBase64.isNotEmpty && !kIsWeb) {
              if(kIsWeb) return;
               final dir = await getApplicationDocumentsDirectory();
              String ext = globalMenuIsPdf ? 'pdf' : 'jpg';
              File mFile = File('/mess_menu_.');
              await mFile.writeAsBytes(base64Decode(menuBase64));
              globalMenuFile = mFile;
              _lastMenuPath = mFile.path;
            } else {
              globalMenuFile = null;
              _lastMenuPath = "";
            }
          }
        }'''

new_menu = '''        if (data['menu'] != null) {
          globalMenuIsPdf = data['menu']['isPdf'] ?? false;
          String menuBase64 = data['menu']['fileBase64'] ?? '';
          if (menuBase64 != _lastDownloadedMenuBase64) {
            _lastDownloadedMenuBase64 = menuBase64;
            if (menuBase64.isNotEmpty && !kIsWeb) {
              if(kIsWeb) return;
               final dir = await getApplicationDocumentsDirectory();
              String ext = globalMenuIsPdf ? 'pdf' : 'jpg';
              File mFile = File('/mess_menu_.');
              await mFile.writeAsBytes(base64Decode(menuBase64));
              globalMenuFile = mFile;
              _lastMenuPath = mFile.path;
            } else {
              globalMenuFile = null;
              _lastMenuPath = "";
            }
          }
        } else {
          globalMenuFile = null;
          _lastMenuPath = "";
          _lastDownloadedMenuBase64 = "";
        }'''

text = text.replace(target_menu, new_menu)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS: Menu cleanup added")
