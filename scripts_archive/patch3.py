import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

# Patch pushMenu
target_menu = """      await _supabase.from('menu').upsert({
        'id': 1,
        'image_url': url,
        'updated_at': DateTime.now().toIso8601String(),
        'is_pdf': globalMenuIsPdf
      });
      // Clear legacy firebase node so it doesn't conflict
      await _dbRef.child('menu').remove();"""
replacement_menu = """      await _supabase.from('menu').upsert({
        'id': 1,
        'image_url': url,
        'updated_at': DateTime.now().toIso8601String(),
        'is_pdf': globalMenuIsPdf
      });
      // Clear legacy firebase node so it doesn't conflict
      await _dbRef.child('menu').remove();
      await _dbRef.child('menu_trigger').set(DateTime.now().millisecondsSinceEpoch);"""
code = code.replace(target_menu, replacement_menu)

# Patch pushMenu delete branch
target_menu_delete = """    if (globalMenuFile == null && globalMenuUploadBytes == null) {
      try {
        await _dbRef.child('menu').remove();
        await _supabase.from('menu').delete().eq('id', 1);
      } catch(e){}
      return;
    }"""
replacement_menu_delete = """    if (globalMenuFile == null && globalMenuUploadBytes == null) {
      try {
        await _dbRef.child('menu').remove();
        await _supabase.from('menu').delete().eq('id', 1);
        await _dbRef.child('menu_trigger').set(DateTime.now().millisecondsSinceEpoch);
      } catch(e){}
      return;
    }"""
code = code.replace(target_menu_delete, replacement_menu_delete)


# Patch deleteNotice
target_delete_notice = """  static Future<void> deleteNotice(String id) async {
    try {
      globalNotices.removeWhere((n) => n.id == id);
      globalSyncTrigger.value++;
      await _supabase.from('notices').delete().eq('id', id);
    } catch(e) {"""
replacement_delete_notice = """  static Future<void> deleteNotice(String id) async {
    try {
      globalNotices.removeWhere((n) => n.id == id);
      globalSyncTrigger.value++;
      await _supabase.from('notices').delete().eq('id', id);
      await _dbRef.child('notices_trigger').set(DateTime.now().millisecondsSinceEpoch);
    } catch(e) {"""
code = code.replace(target_delete_notice, replacement_delete_notice)

# Patch pushNotices
target_push_notices = """  static Future<void> pushNotices() async {
    try {
      for(var n in globalNotices) {
        await _supabase.from('notices').upsert({
          'id': n.id,
          'title': n.title,
          'message': n.message,
          'date': n.date.toIso8601String()
        });
      }
    } catch(e) {"""
replacement_push_notices = """  static Future<void> pushNotices() async {
    try {
      for(var n in globalNotices) {
        await _supabase.from('notices').upsert({
          'id': n.id,
          'title': n.title,
          'message': n.message,
          'date': n.date.toIso8601String()
        });
      }
      await _dbRef.child('notices_trigger').set(DateTime.now().millisecondsSinceEpoch);
    } catch(e) {"""
code = code.replace(target_push_notices, replacement_push_notices)

# Patch _performReset
target_reset = """      SyncService.pushStudents();
      globalSyncTrigger.value++;
      
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All data has been reset!"), backgroundColor: Colors.green));
    } catch(e) {"""
replacement_reset = """      SyncService.pushStudents();
      globalSyncTrigger.value++;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userType');
      await prefs.remove('identifier');
      await prefs.remove('photoPath');
      await prefs.remove('extraInfo');
      await prefs.remove('last_student_name');
      await prefs.remove('last_student_room');
      await prefs.remove('last_student_photo');
      await prefs.remove('last_admin_phone');
      await prefs.remove('last_admin_name');
      await prefs.remove('last_admin_photo');
      
      Navigator.pop(context); // close loading
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All data has been reset!"), backgroundColor: Colors.green));
    } catch(e) {"""
code = code.replace(target_reset, replacement_reset)

with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
print("Patched all fixes")
