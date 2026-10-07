import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target = '''  static Future<void> pushMenu() async {
    if (globalMenuFile == null) {
      try {
        await _dbRef.child('menu').remove();
        await _supabase.from('menu_').delete().eq('id', 1);
        globalSyncTrigger.value++;
    } catch(e){}
      return;
    }
    try {
      final bytes = await globalMenuFile!.readAsBytes();
      final path = 'menu_.jpg';
      await _supabase.storage.from('mess_images').uploadBinary(path, bytes);'''

new_target = '''  static Future<void> pushMenu() async {
    if (globalMenuFile == null && globalMenuUploadBytes == null) {
      try {
        await _dbRef.child('menu').remove();
        await _supabase.from('menu_').delete().eq('id', 1);
        globalSyncTrigger.value++;
    } catch(e){}
      return;
    }
    try {
      final bytes = globalMenuUploadBytes ?? await globalMenuFile!.readAsBytes();
      String ext = globalMenuIsPdf ? 'pdf' : 'jpg';
      final path = 'menu_.';
      await _supabase.storage.from('mess_images').uploadBinary(path, bytes);'''

if target in text:
    text = text.replace(target, new_target)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS: Target replaced!")
else:
    print("FAIL: Target not found.")
