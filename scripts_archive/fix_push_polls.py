import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

search = """  static Future<void> pushPollsNow() async {
    _pollCooldown = true;
    try {
      await _dbRef.child('polls').set({
        'L': todayPollVotes['L']?.toList() ?? [],
        'D': todayPollVotes['D']?.toList() ?? [],
      });
    } catch(e) {"""

replace = """  static Future<void> pushPollsNow() async {
    _pollCooldown = true;
    try {
      await _dbRef.child('polls').runTransaction((Object? post) {
        if (post == null) {
          return Transaction.success({
            'L': todayPollVotes['L']?.toList() ?? [],
            'D': todayPollVotes['D']?.toList() ?? [],
          });
        }
        Map<dynamic, dynamic> data = post as Map<dynamic, dynamic>;
        Set<String> lSet = Set<String>.from(data['L'] ?? []);
        Set<String> dSet = Set<String>.from(data['D'] ?? []);
        lSet.addAll(todayPollVotes['L'] ?? []);
        dSet.addAll(todayPollVotes['D'] ?? []);
        return Transaction.success({
          'L': lSet.toList(),
          'D': dSet.toList(),
        });
      });
    } catch(e) {"""

if search in content:
    content = content.replace(search, replace)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated pushPollsNow to use runTransaction")
else:
    print("search not found")
