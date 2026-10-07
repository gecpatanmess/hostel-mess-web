import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add UI trigger to switchMode
target_switchMode = """    _supabaseStreamsInitialized = false;
    
    listen();"""
new_switchMode = """    _supabaseStreamsInitialized = false;
    
    listen();
    globalSyncTrigger.value++; // Force UI refresh immediately on toggle"""

if target_switchMode in text:
    text = text.replace(target_switchMode, new_switchMode)
else:
    print("WARNING: switchMode target not found")


# 2. Add explicit fetch for menu in fetchNow (as a fallback for stream)
target_fetchNow = """    if (snap.exists && snap.value != null) {
      Map<dynamic, dynamic> rawData = snap.value as Map<dynamic, dynamic>;"""
new_fetchNow = """    if (snap.exists && snap.value != null) {
      Map<dynamic, dynamic> rawData = snap.value as Map<dynamic, dynamic>;
      
      // Explicitly fetch Supabase menu to fix disappearing bug on refresh
      try {
        final menuData = await _supabase.from('menu_$globalHostelMode').select().eq('id', 1);
        if (menuData.isNotEmpty) {
          globalMenuUrl = menuData.first['image_url'];
          globalMenuIsPdf = (globalMenuUrl ?? '').toLowerCase().contains('.pdf');
        } else {
          globalMenuUrl = null;
        }
      } catch(e) {
        print("Menu fetch error: $e");
      }"""

if target_fetchNow in text:
    text = text.replace(target_fetchNow, new_fetchNow)
else:
    print("WARNING: fetchNow target not found")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Fixes applied")
