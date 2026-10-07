import os

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import re

old_func = re.search(r'static void initSupabaseStreams\(\) \{.*?(?=  static void init|  _firebaseSub = _firebaseSub =)', code, re.DOTALL)
if not old_func:
    print("Could not find initSupabaseStreams block.")
else:
    old_str = old_func.group(0)

    # Note that old_str ends before the next function. Let's make a precise replacement block.
    # We will just write a completely new function string.
    new_func = """  static void initSupabaseStreams() {
    if (_supabaseStreamsInitialized) return;
    _supabaseStreamsInitialized = true;
    
    _supaMenuSub = _supabase.from('menu_$globalHostelMode').stream(primaryKey: ['id']).listen((data) async {
      if (data.isNotEmpty) {
        String imgUrl = data.first['image_url'] ?? '';
        globalMenuUrl = imgUrl;
        globalMenuIsPdf = imgUrl.toLowerCase().contains('.pdf');
        
        if (imgUrl.isNotEmpty) {
            try {
               final response = await _supabase.storage.from('mess_images').download(imgUrl.split('/').last);
               if(!kIsWeb) {
                   final dir = await getApplicationDocumentsDirectory();
                   File mFile = File('${dir.path}/mess_menu_supabase.jpg');
                   await mFile.writeAsBytes(response);
                   globalMenuFile = mFile;
               }
            } catch(e) {}
        } else {
            globalMenuFile = null;
        }
      } else {
        globalMenuUrl = null;
        globalMenuFile = null;
      }
      globalSyncTrigger.value++;
    });
    
    _supaNoticesSub = _supabase.from('notices_$globalHostelMode').stream(primaryKey: ['id']).listen((data) {
      globalNotices.clear();
      for(var n in data) {
        globalNotices.add(NoticeItem(n['id'].toString(), n['title'], n['message'], DateTime.parse(n['date'])));
      }
      globalSyncTrigger.value++;
    });

    _supaComplaintsSub = _supabase.from('complaints_$globalHostelMode').stream(primaryKey: ['id']).listen((data) async {
      globalComplaints.clear();
      for(var c in data) {
        String? sPhoto = null;
        try {
          sPhoto = globalRegisteredStudents.firstWhere((s) => s.roomNo == c['student_room'] && s.name == c['student_name']).photoUrl;
        } catch(e){}
        globalComplaints.add(ComplaintItem(
          c['id'].toString(), c['title'], c['description'],
          DateTime.parse(c['date']), c['student_name'], c['student_room'], sPhoto, c['image_url']
        ));
      }
      globalSyncTrigger.value++;
    });
  }

"""
    # Replace the old function with the new one
    code = code.replace(old_str, new_func)

    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Successfully replaced initSupabaseStreams")
