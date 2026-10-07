import 'dart:io';

void main() {
  File mainFile = File('lib/main.dart');
  String content = mainFile.readAsStringSync();
  
  // =================== PUSH ALL ===================
  String pushAdditions = '''
    // Complaints
    List<Map<String, dynamic>> cList = [];
    for (var c in globalComplaints) {
      cList.add({
        'id': c.id,
        'title': c.title,
        'description': c.description,
        'date': c.date.toIso8601String(),
        'studentName': c.studentName,
        'studentRoom': c.studentRoom
      });
    }
    data['complaints'] = cList;

    // Menu File
    String menuBase64 = "";
    if (globalMenuFile != null && globalMenuFile!.existsSync() && !kIsWeb) {
      try {
        menuBase64 = base64Encode(await globalMenuFile!.readAsBytes());
      } catch(e){}
    }
    data['menu'] = {
      'isPdf': globalMenuIsPdf,
      'fileBase64': menuBase64
    };

    data['hiddenNotices'] = globalStudentHiddenNotices.toList();
    data['hiddenComplaints'] = globalStudentHiddenComplaints.toList();
    data['adminLastViewed'] = globalAdminLastViewedComplaints.toIso8601String();
''';

  if (!content.contains("data['complaints'] = cList;")) {
    content = content.replaceFirst(
      "int currentHash = _computeHash(data);",
      pushAdditions + "\n    int currentHash = _computeHash(data);"
    );
  }

  // =================== LISTEN ===================
  String listenAdditions = '''
        if (data['complaints'] != null) {
          globalComplaints.clear();
          for(var c in (data['complaints'] as List)) {
            globalComplaints.add(ComplaintItem(
              c['id'], c['title'], c['description'],
              DateTime.parse(c['date']), c['studentName'], c['studentRoom']
            ));
          }
        }
        
        if (data['menu'] != null) {
          globalMenuIsPdf = data['menu']['isPdf'] ?? false;
          String menuBase64 = data['menu']['fileBase64'] ?? '';
          if (menuBase64.isNotEmpty && !kIsWeb) {
            final dir = await getApplicationDocumentsDirectory();
            String ext = globalMenuIsPdf ? 'pdf' : 'jpg';
            File mFile = File('\${dir.path}/mess_menu.\$ext');
            await mFile.writeAsBytes(base64Decode(menuBase64));
            globalMenuFile = mFile;
          } else {
            globalMenuFile = null;
          }
        }

        if (data['hiddenNotices'] != null) {
          globalStudentHiddenNotices = Set<String>.from(data['hiddenNotices']);
        }
        if (data['hiddenComplaints'] != null) {
          globalStudentHiddenComplaints = Set<String>.from(data['hiddenComplaints']);
        }
        if (data['adminLastViewed'] != null) {
          globalAdminLastViewedComplaints = DateTime.parse(data['adminLastViewed']);
        }
''';

  if (!content.contains("if (data['complaints'] != null) {")) {
    content = content.replaceFirst(
      "if (data['notices'] != null) {",
      listenAdditions + "\n        if (data['notices'] != null) {"
    );
  }

  mainFile.writeAsStringSync(content);
  print("All features added to Firebase Sync!");
}
