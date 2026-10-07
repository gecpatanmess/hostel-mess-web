import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace pushNotices
push_notices = '''static Future<void> pushNotices() async {
    try {
      for(var n in globalNotices) {
        await _supabase.from('notices').upsert({
          'id': n.id,
          'title': n.title,
          'message': n.message,
          'date': n.date.toIso8601String()
        });
      }
    } catch(e) {
      print("Push notices error: $e");
    }
  }'''

code = re.sub(r'static Future<void> pushNotices\(\) async \{.*?\n  \}', push_notices, code, flags=re.DOTALL)

# Replace pushComplaints
push_complaints = '''static Future<void> pushComplaints() async {
    try {
      for(var c in globalComplaints) {
        String photoUrl = ""; // upload to storage if needed, but skipping base64 logic to keep it fast
        await _supabase.from('complaints').upsert({
          'id': c.id,
          'title': c.title,
          'description': c.description,
          'date': c.date.toIso8601String(),
          'student_name': c.studentName,
          'student_room': c.studentRoom,
          'image_url': photoUrl
        });
      }
    } catch(e) {
      print("Push complaints error: $e");
    }
  }'''

code = re.sub(r'static Future<void> pushComplaints\(\) async \{.*?\n  \}', push_complaints, code, flags=re.DOTALL)


# Replace pushMenu
push_menu = '''static Future<void> pushMenu() async {
    if (globalMenuFile == null) return;
    try {
      final bytes = await globalMenuFile!.readAsBytes();
      final path = 'menu_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('mess_images').uploadBinary(path, bytes);
      final url = _supabase.storage.from('mess_images').getPublicUrl(path);
      
      await _supabase.from('menu').upsert({
        'id': 1,
        'image_url': url,
        'updated_at': DateTime.now().toIso8601String()
      });
    } catch(e) {
      print("Push menu error: $e");
    }
  }'''

code = re.sub(r'static Future<void> pushMenu\(\) async \{.*?\n  \}', push_menu, code, flags=re.DOTALL)


with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("push methods replaced")
