import re

with open('android/app/src/main/AndroidManifest.xml', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove all uses-permission tags
content = re.sub(r'<uses-permission android:name="[^"]+" />\n?', '', content)

# Add them back once
permissions = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
"""

content = content.replace('<application', permissions + '<application')

with open('android/app/src/main/AndroidManifest.xml', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed AndroidManifest")
