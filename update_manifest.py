import re

with open('android/app/src/main/AndroidManifest.xml', 'r', encoding='utf-8') as f:
    manifest = f.read()

permissions = '''<uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />'''

manifest = manifest.replace('<uses-permission android:name="android.permission.INTERNET"/>', permissions)

with open('android/app/src/main/AndroidManifest.xml', 'w', encoding='utf-8') as f:
    f.write(manifest)

print("AndroidManifest updated")
