import 'dart:io';

void main() {
  File manifestFile = File('android/app/src/main/AndroidManifest.xml');
  String content = manifestFile.readAsStringSync();
  
  if (!content.contains('<uses-permission android:name="android.permission.INTERNET"/>')) {
    content = content.replaceFirst(
      '<application',
      '<uses-permission android:name="android.permission.INTERNET"/>\n    <application'
    );
    manifestFile.writeAsStringSync(content);
    print("Internet permission added.");
  } else {
    print("Internet permission already exists.");
  }
}
