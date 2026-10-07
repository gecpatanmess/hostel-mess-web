import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target = '''  static Future<void> switchMode(String mode) async {
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

new_target = '''  static Future<void> switchMode(String mode) async {
    globalHostelMode = mode;
    _hasDownloadedOnce = false;
    _lastHash = 0;
    
    globalMenuFile = null;
    globalMenuUrl = null;
    _lastDownloadedMenuBase64 = "";
    _lastMenuPath = "";
    globalNotices.clear();
    globalComplaints.clear();
    globalRegisteredStudents.clear();
    globalAdmins.clear();
    dynamicPolls.clear();
    globalAttendanceMap.clear();
    globalMonthlyPaid.clear();

    await _firebaseSub?.cancel();
    await _supaNoticesSub?.cancel();
    await _supaComplaintsSub?.cancel();
    _supabaseStreamsInitialized = false;
    
    listen();
    await fetchNow();
  }'''

text = text.replace(target, new_target)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Full reset added to switchMode")
