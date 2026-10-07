with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

old_str = """            try {
               final response = await _supabase.storage.from('mess_images').download(imgUrl.split('/').last);
               if(!kIsWeb) {
                   final dir = await getApplicationDocumentsDirectory();
                   File mFile = File('${dir.path}/mess_menu_supabase.jpg');
                   await mFile.writeAsBytes(response);
                   globalMenuFile = mFile;
               }
            } catch(e) {}"""

new_str = """            try {
               final response = await _supabase.storage.from('mess_images').download(imgUrl.split('/').last);
               if(!kIsWeb) {
                   final dir = await getApplicationDocumentsDirectory();
                   File mFile = File('${dir.path}/mess_menu_supabase.jpg');
                   await mFile.writeAsBytes(response);
                   globalMenuFile = mFile;
               } else {
                   globalMenuUploadBytes = response;
               }
            } catch(e) {}"""

code = code.replace(old_str, new_str)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print('Web memory image fix applied')
