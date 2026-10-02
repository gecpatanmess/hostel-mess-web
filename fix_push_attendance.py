import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

search = """  static Future<void> pushAttendance(String key, DailyRecord rec) async {
    try {
      await _dbRef.child('attendance').child(key).set({
        'l': rec.l,
        'd': rec.d,
      });
    } catch(e) {"""

replace = """  static Future<void> pushAttendance(String key, DailyRecord rec) async {
    try {
      Map<String, dynamic> updateData = {};
      if (rec.l.isNotEmpty) updateData['l'] = rec.l;
      if (rec.d.isNotEmpty) updateData['d'] = rec.d;
      if (updateData.isNotEmpty) {
        await _dbRef.child('attendance').child(key).update(updateData);
      }
    } catch(e) {"""

if search in content:
    content = content.replace(search, replace)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated pushAttendance to use update()")
else:
    print("search not found")
