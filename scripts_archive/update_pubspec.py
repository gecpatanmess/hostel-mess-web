import re

with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    text = f.read()

old = """flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true"""

new = """flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  assets:
    - assets/mdhk_logo.png
    - assets/logo.jpg"""

if "assets/mdhk_logo.png" not in text:
    text = text.replace(old, new)
    with open('pubspec.yaml', 'w', encoding='utf-8') as f:
        f.write(text)
    print("Added assets to pubspec.yaml")
else:
    print("Already added")
