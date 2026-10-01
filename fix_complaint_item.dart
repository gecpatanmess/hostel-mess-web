import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  String oldStr = '''
          for(var c in (data['complaints'] as List)) {
            globalComplaints.add(ComplaintItem(
              c['id'], c['title'], c['description'],
              DateTime.parse(c['date']), c['studentName'], c['studentRoom']
            ));
          }
''';

  String newStr = '''
          for(var c in (data['complaints'] as List)) {
            // Find student photo from global list
            File sPhoto = File('dummy.png');
            try {
              sPhoto = globalRegisteredStudents.firstWhere((s) => s.roomNo == c['studentRoom'] && s.name == c['studentName']).photo;
            } catch(e){}
            
            globalComplaints.add(ComplaintItem(
              c['id'], c['title'], c['description'],
              DateTime.parse(c['date']), c['studentName'], c['studentRoom'], sPhoto
            ));
          }
''';

  content = content.replaceFirst(oldStr, newStr);
  
  file.writeAsStringSync(content);
}
