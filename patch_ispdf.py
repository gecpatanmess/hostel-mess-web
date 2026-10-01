import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix 1: Remove is_pdf from upsert
target_push = """      await _supabase.from('menu').upsert({
        'id': 1,
        'image_url': url,
        'updated_at': DateTime.now().toIso8601String(),
        'is_pdf': globalMenuIsPdf
      });"""
replacement_push = """      await _supabase.from('menu').upsert({
        'id': 1,
        'image_url': url,
        'updated_at': DateTime.now().toIso8601String()
      });"""
code = code.replace(target_push, replacement_push)

# Fix 2: Remove is_pdf from StreamBuilder
target_stream = """        String imgUrl = snapshot.data!.first['image_url'] ?? '';
        bool isPdf = snapshot.data!.first['is_pdf'] ?? false;
        
        if (imgUrl.isEmpty) {"""
replacement_stream = """        String imgUrl = snapshot.data!.first['image_url'] ?? '';
        bool isPdf = imgUrl.toLowerCase().contains('.pdf');
        
        if (imgUrl.isEmpty) {"""
code = code.replace(target_stream, replacement_stream)

# Fix 3: Remove is_pdf from manual stream listen (if still there)
target_manual_stream = """         String imgUrl = data.first['image_url'] ?? '';
         bool isPdf = data.first['is_pdf'] ?? false;
         if (imgUrl.isNotEmpty) {"""
replacement_manual_stream = """         String imgUrl = data.first['image_url'] ?? '';
         bool isPdf = imgUrl.toLowerCase().contains('.pdf');
         if (imgUrl.isNotEmpty) {"""
code = code.replace(target_manual_stream, replacement_manual_stream)

# Fix 4: Remove is_pdf from manual select (if still there)
target_manual_select = """               globalMenuUrl = resp.first['image_url'];
               globalMenuIsPdf = resp.first['is_pdf'] ?? false;
            } else {"""
replacement_manual_select = """               globalMenuUrl = resp.first['image_url'];
               globalMenuIsPdf = (globalMenuUrl ?? '').toLowerCase().contains('.pdf');
            } else {"""
code = code.replace(target_manual_select, replacement_manual_select)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Patched is_pdf bug")
