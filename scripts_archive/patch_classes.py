import re
with open('lib/main.dart', 'r', encoding='utf-8') as f: code = f.read()

rs_old = """class RegisteredStudent {
  final String name;
  final String roomNo;
  String? photoUrl;
  String pin;
  RegisteredStudent(this.name, this.roomNo, this.photoUrl, this.pin);

  Map<String, dynamic> toJson() => {
    'name': name,
    'roomNo': roomNo,
    'photoUrl': photoUrl ?? '',
    'pin': pin,
  };
  factory RegisteredStudent.fromJson(Map<String, dynamic> json) => RegisteredStudent(
    json['name'],
    json['roomNo'],
    json['photoUrl'] ?? json['photo'],
    json['pin'],
  );
}"""

rs_new = """class RegisteredStudent {
  final String name;
  final String roomNo;
  String? photoUrl;
  String pin;
  String email;
  RegisteredStudent(this.name, this.roomNo, this.photoUrl, this.pin, {this.email = ''});

  Map<String, dynamic> toJson() => {
    'name': name,
    'roomNo': roomNo,
    'photoUrl': photoUrl ?? '',
    'pin': pin,
    'email': email,
  };
  factory RegisteredStudent.fromJson(Map<String, dynamic> json) => RegisteredStudent(
    json['name'],
    json['roomNo'],
    json['photoUrl'] ?? json['photo'],
    json['pin'],
    email: json['email'] ?? '',
  );
}"""
code = code.replace(rs_old, rs_new)

au_old = """class AdminUser {
  String phone;
  String pin;
  AdminUser(this.phone, this.pin);

  Map<String, dynamic> toJson() => {'phone': phone, 'pin': pin};
  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(json['phone'], json['pin']);
}"""

au_new = """class AdminUser {
  String phone;
  String pin;
  String email;
  AdminUser(this.phone, this.pin, {this.email = ''});

  Map<String, dynamic> toJson() => {'phone': phone, 'pin': pin, 'email': email};
  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(json['phone'], json['pin'], email: json['email'] ?? '');
}"""
code = code.replace(au_old, au_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f: f.write(code)
