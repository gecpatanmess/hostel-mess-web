with open('lib/update_service.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old_str = """      final response = await _supabase
          .from('app_updates_$globalHostelMode')
          .select('version, apk_url, ios_url, is_mandatory')"""

new_str = """      final response = await _supabase
          .from('app_updates')
          .select('version, apk_url, ios_url, is_mandatory')"""

code = code.replace(old_str, new_str)

with open('lib/update_service.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print('app_updates table name fixed!')
