import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add delete methods in SyncService
delete_methods = '''
  static Future<void> deleteNotice(String id) async {
    try {
      await _supabase.from('notices').delete().eq('id', id);
    } catch(e) {
      print("Delete notice error: $e");
    }
  }

  static Future<void> deleteComplaint(String id) async {
    try {
      await _supabase.from('complaints').delete().eq('id', id);
    } catch(e) {
      print("Delete complaint error: $e");
    }
  }
'''
if 'deleteNotice' not in code:
    code = code.replace('static Future<void> pushNotices() async {', delete_methods + '\n  static Future<void> pushNotices() async {')

# 2. Modify admin notice delete button
admin_notice_delete = '''icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          SyncService.deleteNotice(notice.id);
                        });
                      },'''
code = re.sub(r'icon: const Icon\(\s*Icons\.delete_outline,\s*color: Colors\.redAccent,\s*\),\s*onPressed: \(\) \{\s*setState\(\(\) \{\s*globalAdminHiddenNotices\.add\(notice\.id\);\s*\}\);\s*\},', admin_notice_delete, code, flags=re.DOTALL)

# 3. Modify Admin complaints delete button logic
admin_complaints_delete = '''onDelete: (id) {
                            SyncService.deleteComplaint(id);
                          }'''
code = re.sub(r'onDelete: \(id\) => setState\(\(\) \{\s*globalComplaints\.removeWhere\(\(c\) => c\.id == id\);\s*SyncService\.pushComplaints\(\);\s*\}\)', admin_complaints_delete, code, flags=re.DOTALL)


with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Delete logic updated")
