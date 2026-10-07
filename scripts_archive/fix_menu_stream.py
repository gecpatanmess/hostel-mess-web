import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target = '''  static void initSupabaseStreams() {
    if (_supabaseStreamsInitialized) return;
    _supabaseStreamsInitialized = true;
    
    _supaNoticesSub = _supabase.from('notices_').stream(primaryKey: ['id']).listen((data) {'''

new_target = '''  static StreamSubscription? _supaMenuSub;

  static void initSupabaseStreams() {
    if (_supabaseStreamsInitialized) return;
    _supabaseStreamsInitialized = true;
    
    _supaMenuSub = _supabase.from('menu_').stream(primaryKey: ['id']).listen((data) {
      if (data.isNotEmpty) {
        globalMenuUrl = data.first['image_url'];
        globalMenuIsPdf = (globalMenuUrl ?? '').toLowerCase().contains('.pdf');
      } else {
        globalMenuUrl = null;
      }
      globalSyncTrigger.value++;
    });

    _supaNoticesSub = _supabase.from('notices_').stream(primaryKey: ['id']).listen((data) {'''

text = text.replace(target, new_target)

# Add to switchMode
target2 = '''    await _supaNoticesSub?.cancel();'''
new_target2 = '''    await _supaMenuSub?.cancel();
    await _supaNoticesSub?.cancel();'''
text = text.replace(target2, new_target2)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Added menu stream")
