import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target_fetchNow = """      if (snap.exists && snap.value != null) {
        Map<dynamic, dynamic> rawData = snap.value as Map<dynamic, dynamic>;"""

new_fetchNow = """      if (snap.exists && snap.value != null) {
        Map<dynamic, dynamic> rawData = snap.value as Map<dynamic, dynamic>;
        
        try {
          final menuData = await _supabase.from('menu_$globalHostelMode').select().eq('id', 1);
          if (menuData.isNotEmpty) {
            globalMenuUrl = menuData.first['image_url'];
            globalMenuIsPdf = (globalMenuUrl ?? '').toLowerCase().contains('.pdf');
          } else {
            globalMenuUrl = null;
          }
        } catch(e) {}"""

if target_fetchNow in text:
    text = text.replace(target_fetchNow, new_fetchNow)
    print("SUCCESS: fetchNow fixed")
else:
    print("WARNING: fetchNow target not found")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
