import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add variables before switchMode
target = "  static Future<void> switchMode(String mode) async {"
new_target = '''  static StreamSubscription? _firebaseSub;
  static StreamSubscription? _supaNoticesSub;
  static StreamSubscription? _supaComplaintsSub;

  static Future<void> switchMode(String mode) async {'''
text = text.replace(target, new_target)

# 2. Add cancel logic inside switchMode
target_switch = '''  static Future<void> switchMode(String mode) async {
    globalHostelMode = mode;
    _hasDownloadedOnce = false;
    _lastHash = 0;
    await fetchNow();
  }'''
new_switch = '''  static Future<void> switchMode(String mode) async {
    globalHostelMode = mode;
    _hasDownloadedOnce = false;
    _lastHash = 0;
    
    await _firebaseSub?.cancel();
    await _supaNoticesSub?.cancel();
    await _supaComplaintsSub?.cancel();
    _supabaseStreamsInitialized = false;
    
    listen();
    await fetchNow();
  }'''
text = text.replace(target_switch, new_switch)

# 3. Assign _supaNoticesSub
target_notices = "_supabase.from('notices_').stream(primaryKey: ['id']).listen((data) {"
new_notices = "_supaNoticesSub = _supabase.from('notices_').stream(primaryKey: ['id']).listen((data) {"
text = text.replace(target_notices, new_notices)

# 4. Assign _supaComplaintsSub
target_comp = "_supabase.from('complaints_').stream(primaryKey: ['id']).listen((data) async {"
new_comp = "_supaComplaintsSub = _supabase.from('complaints_').stream(primaryKey: ['id']).listen((data) async {"
text = text.replace(target_comp, new_comp)

# 5. Assign _firebaseSub
target_fire = "_dbRef.onValue.listen((event) async {"
new_fire = "_firebaseSub = _dbRef.onValue.listen((event) async {"
text = text.replace(target_fire, new_fire)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS")
