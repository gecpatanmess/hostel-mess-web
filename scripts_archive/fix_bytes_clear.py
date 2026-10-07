import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target = '''  static Future<void> switchMode(String mode) async {
    globalHostelMode = mode;
    _hasDownloadedOnce = false;
    _lastHash = 0;
    
    globalMenuFile = null;
    globalMenuUrl = null;'''

new_target = '''  static Future<void> switchMode(String mode) async {
    globalHostelMode = mode;
    _hasDownloadedOnce = false;
    _lastHash = 0;
    
    globalMenuFile = null;
    globalMenuUrl = null;
    globalMenuUploadBytes = null;
    globalMenuIsPdf = false;'''

text = text.replace(target, new_target)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Added globalMenuUploadBytes clearing")
