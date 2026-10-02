import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

search_func = """  static Future<void> pushPollsNow() async {
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

replace_func = """  static Future<void> pushPollsNow({bool clear = false}) async {
    _pollCooldown = true;
    try {
      if (clear) {
        await _dbRef.child('polls').set({
          'L': [],
          'D': [],
        });
      } else {
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
      }
    } catch(e) {"""

content = content.replace(search_func, replace_func)

search_clear = """                        setState(() {
                          todayPollVotes = {'L': <String>{}, 'D': <String>{}};
                        });
                        SyncService.pushPollsNow();
                        ScaffoldMessenger.of(context).showSnackBar("""

replace_clear = """                        setState(() {
                          todayPollVotes = {'L': <String>{}, 'D': <String>{}};
                        });
                        SyncService.pushPollsNow(clear: true);
                        ScaffoldMessenger.of(context).showSnackBar("""

content = content.replace(search_clear, replace_clear)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated pushPollsNow with clear flag")
