import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

# Add _dbRef.child('menu').set({...}) inside pushMenu
old_push_menu = """        await _supabase.from('menu').upsert({
          'id': 1,
          'image_url': url,
          'updated_at': DateTime.now().toIso8601String(),
          'is_pdf': globalMenuIsPdf
        });"""

new_push_menu = """        await _supabase.from('menu').upsert({
          'id': 1,
          'image_url': url,
          'updated_at': DateTime.now().toIso8601String(),
          'is_pdf': globalMenuIsPdf
        });
        await _dbRef.child('menu_trigger').set(DateTime.now().toIso8601String());"""

code = code.replace(old_push_menu, new_push_menu)

# Same for notices
old_push_notices = """      for(var n in globalNotices) {
        await _supabase.from('notices').upsert({
          'id': int.parse(n.id),
          'title': n.title,
          'message': n.message,
          'date': n.date.toIso8601String()
        });
      }"""

new_push_notices = """      for(var n in globalNotices) {
        await _supabase.from('notices').upsert({
          'id': int.parse(n.id),
          'title': n.title,
          'message': n.message,
          'date': n.date.toIso8601String()
        });
      }
      await _dbRef.child('notices_trigger').set(DateTime.now().toIso8601String());"""

code = code.replace(old_push_notices, new_push_notices)

# For delete notice
old_delete_notice = """    static Future<void> deleteNotice(String id) async {
      globalNotices.removeWhere((n) => n.id == id);
      try {
        await _supabase.from('notices').delete().eq('id', int.parse(id));
      } catch(e) {}
    }"""
new_delete_notice = """    static Future<void> deleteNotice(String id) async {
      globalNotices.removeWhere((n) => n.id == id);
      try {
        await _supabase.from('notices').delete().eq('id', int.parse(id));
        await _dbRef.child('notices_trigger').set(DateTime.now().toIso8601String());
      } catch(e) {}
    }"""
code = code.replace(old_delete_notice, new_delete_notice)

# And inside _dbRef.onValue.listen, we should trigger a fetch from supabase
old_onvalue = """        if (data['switches'] != null && !_switchCooldown) {"""
new_onvalue = """        if (data['menu_trigger'] != null || data['notices_trigger'] != null) {
          // If triggers changed, force fetch Supabase data directly
          _supabase.from('menu').select().eq('id', 1).then((resp) {
            if (resp.isNotEmpty) {
               globalMenuUrl = resp.first['image_url'];
               globalMenuIsPdf = resp.first['is_pdf'] ?? false;
            } else {
               globalMenuUrl = null;
            }
            globalSyncTrigger.value++;
          });
        }

        if (data['switches'] != null && !_switchCooldown) {"""

code = code.replace(old_onvalue, new_onvalue)

with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
print("Sync triggers added!")
