import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Add stream variables and cancel logic to switchMode
text = text.replace(
'''  static final _supabase = Supabase.instance.client;
  static DatabaseReference get _dbRef => FirebaseDatabase.instance.ref('hostelData_');
  static bool _isSyncingIn = false;
  static bool _hasDownloadedOnce = false;
  static int _lastHash = 0;
  static String _lastMenuPath = "";
  static String _lastDownloadedMenuBase64 = "";
  static bool _switchCooldown = false;
  static bool _pollCooldown = false;

  static Future<void> switchMode(String mode) async {
    globalHostelMode = mode;
    _hasDownloadedOnce = false;
    _lastHash = 0;
    await fetchNow();
  }''',
'''  static final _supabase = Supabase.instance.client;
  static DatabaseReference get _dbRef => FirebaseDatabase.instance.ref('hostelData_');
  static bool _isSyncingIn = false;
  static bool _hasDownloadedOnce = false;
  static int _lastHash = 0;
  static String _lastMenuPath = "";
  static String _lastDownloadedMenuBase64 = "";
  static bool _switchCooldown = false;
  static bool _pollCooldown = false;
  
  static StreamSubscription? _firebaseSub;
  static StreamSubscription? _supaNoticesSub;
  static StreamSubscription? _supaComplaintsSub;

  static Future<void> switchMode(String mode) async {
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
)

text = text.replace(
'''  static void initSupabaseStreams() {
    if (_supabaseStreamsInitialized) return;
    _supabaseStreamsInitialized = true;
    
    _supabase.from('notices_').stream(primaryKey: ['id']).listen((data) {''',
'''  static void initSupabaseStreams() {
    if (_supabaseStreamsInitialized) return;
    _supabaseStreamsInitialized = true;
    
    _supaNoticesSub = _supabase.from('notices_').stream(primaryKey: ['id']).listen((data) {'''
)

text = text.replace(
'''    _supabase.from('complaints_').stream(primaryKey: ['id']).listen((data) async {''',
'''    _supaComplaintsSub = _supabase.from('complaints_').stream(primaryKey: ['id']).listen((data) async {'''
)

text = text.replace(
'''  static void listen() {
    initSupabaseStreams();

    _dbRef.onValue.listen((event) async {''',
'''  static void listen() {
    initSupabaseStreams();

    _firebaseSub = _dbRef.onValue.listen((event) async {'''
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Streams are now dynamic!")
