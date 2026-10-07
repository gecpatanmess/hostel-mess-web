import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  // Fix Notice toJson
  content = content.replaceFirst(
    "for(var n in globalNotices) nList.add(n.toJson());",
    "for(var n in globalNotices) nList.add({'id': n.id, 'title': n.title, 'message': n.message, 'date': n.date.toIso8601String()});"
  );
  
  // Fix Set casting in pushAll
  content = content.replaceFirst(
    "data['polls'] = {'L': todayPollVotes['L'], 'D': todayPollVotes['D']};",
    "data['polls'] = {'L': todayPollVotes['L']?.toList() ?? [], 'D': todayPollVotes['D']?.toList() ?? []};"
  );
  
  // Fix Set casting in listen
  content = content.replaceFirst(
    "todayPollVotes['L'] = List<String>.from(data['polls']['L'] ?? []);",
    "todayPollVotes['L'] = Set<String>.from(data['polls']['L'] ?? []);"
  );
  content = content.replaceFirst(
    "todayPollVotes['D'] = List<String>.from(data['polls']['D'] ?? []);",
    "todayPollVotes['D'] = Set<String>.from(data['polls']['D'] ?? []);"
  );
  
  // Fix Notice fromJson
  content = content.replaceFirst(
    "globalNotices.add(Notice.fromJson(Map<String,dynamic>.from(n)));",
    "globalNotices.add(NoticeItem(n['id'], n['title'], n['message'], DateTime.parse(n['date'])));"
  );

  File('lib/main.dart').writeAsStringSync(content);
}
