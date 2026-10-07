import 'dart:io';

void main() {
  File mainFile = File('lib/main.dart');
  String content = mainFile.readAsStringSync();
  
  // Prevent push if empty string
  if (!content.contains("static bool _hasDownloadedOnce = false;")) {
    content = content.replaceFirst(
      "static bool _isSyncingIn = false;",
      "static bool _isSyncingIn = false;\n  static bool _hasDownloadedOnce = false;"
    );
    
    content = content.replaceFirst(
      "if (_isSyncingIn) return;",
      "if (_isSyncingIn) return;\n    if (!_hasDownloadedOnce && globalRegisteredStudents.isEmpty) return; // Prevent wiping cloud on fresh install"
    );

    // Set _hasDownloadedOnce to true when data is received
    content = content.replaceFirst(
      "_isSyncingIn = true;\n      try {",
      "_isSyncingIn = true;\n      _hasDownloadedOnce = true;\n      try {"
    );

    mainFile.writeAsStringSync(content);
    print("SyncService clash protection added.");
  } else {
    print("Clash protection already exists.");
  }
}
