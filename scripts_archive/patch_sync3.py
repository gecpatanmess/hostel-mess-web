import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

old_onval = """          // If triggers changed, force fetch Supabase data directly
          _supabase.from('menu').select().eq('id', 1).then((resp) {
            if (resp.isNotEmpty) {
               globalMenuUrl = resp.first['image_url'];
               globalMenuIsPdf = resp.first['is_pdf'] ?? false;
            } else {
               globalMenuUrl = null;
            }
            globalSyncTrigger.value++;
          });
        }"""

new_onval = """          // If triggers changed, force fetch Supabase data directly
          _supabase.from('menu').select().eq('id', 1).then((resp) {
            if (resp.isNotEmpty) {
               globalMenuUrl = resp.first['image_url'];
               globalMenuIsPdf = resp.first['is_pdf'] ?? false;
            } else {
               globalMenuUrl = null;
            }
            globalSyncTrigger.value++;
          });
          _supabase.from('notices').select().then((resp) {
            globalNotices.clear();
            for(var n in resp) {
              globalNotices.add(NoticeItem(n['id'].toString(), n['title'], n['message'], DateTime.parse(n['date'])));
            }
            globalSyncTrigger.value++;
          });
        }"""
code = code.replace(old_onval, new_onval)
with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
