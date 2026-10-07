import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Add declaration
text = text.replace(
    '  static StreamSubscription? _supaComplaintsSub;',
    '  static StreamSubscription? _supaComplaintsSub;\n  static StreamSubscription? _supaMenuSub;'
)

# Add init stream
target = r"(_supabaseStreamsInitialized = true;\s*)(_supabase\.from\('notices_\$globalHostelMode'\)\.stream\(primaryKey: \['id'\]\)\.listen\(\(data\) \{)"

new_code = r"""\1_supaMenuSub = _supabase.from('menu_$globalHostelMode').stream(primaryKey: ['id']).listen((data) {
      if (data.isNotEmpty) {
        globalMenuUrl = data.first['image_url'];
        globalMenuIsPdf = (globalMenuUrl ?? '').toLowerCase().contains('.pdf');
      } else {
        globalMenuUrl = null;
      }
      globalSyncTrigger.value++;
    });
    
    \2"""

text = re.sub(target, new_code, text)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Fixed menu stream correctly")
