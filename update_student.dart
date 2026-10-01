import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  String oldClass = '''
class RegisteredStudent {
  final String name;
  final String roomNo;
  File photo;
  String pin;
  RegisteredStudent(this.name, this.roomNo, this.photo, this.pin);
}
''';

  String newClass = '''
class RegisteredStudent {
  final String name;
  final String roomNo;
  File photo;
  String pin;
  RegisteredStudent(this.name, this.roomNo, this.photo, this.pin);

  Map<String, dynamic> toJson() => {
    'name': name,
    'roomNo': roomNo,
    'photo': photo.path,
    'pin': pin,
  };
  factory RegisteredStudent.fromJson(Map<String, dynamic> json) => RegisteredStudent(
    json['name'],
    json['roomNo'],
    File(json['photo']),
    json['pin'],
  );
}

Future<void> saveRegisteredStudents() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> strs = globalRegisteredStudents.map((s) => jsonEncode(s.toJson())).toList();
  await prefs.setStringList('globalRegisteredStudents', strs);
}
''';

  content = content.replaceFirst(oldClass.trim(), newClass.trim());
  File('lib/main.dart').writeAsStringSync(content);
}
