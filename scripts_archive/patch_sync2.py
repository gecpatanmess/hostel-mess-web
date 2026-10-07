import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

old_delete = """      if (globalMenuFile == null && globalMenuUploadBytes == null) {
        try {
          await _dbRef.child('menu').remove();
          await _supabase.from('menu').delete().eq('id', 1);
        } catch(e){}
        return;
      }"""
new_delete = """      if (globalMenuFile == null && globalMenuUploadBytes == null) {
        try {
          await _dbRef.child('menu').remove();
          await _supabase.from('menu').delete().eq('id', 1);
          await _dbRef.child('menu_trigger').set(DateTime.now().toIso8601String());
        } catch(e){}
        return;
      }"""
code = code.replace(old_delete, new_delete)
with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
