import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Update RegisteredStudent and AdminUser to include 'email'
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
    json['photoUrl'] == '' ? null : json['photoUrl'],
    json['pin'] ?? '',
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
    json['photoUrl'] == '' ? null : json['photoUrl'],
    json['pin'] ?? '',
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

# Update push logic to include email
push_students_old = """        studentsList.add({
          'name': s.name, 'roomNo': s.roomNo, 'pin': s.pin, 'photoUrl': photoUrl,
        });"""
push_students_new = """        studentsList.add({
          'name': s.name, 'roomNo': s.roomNo, 'pin': s.pin, 'photoUrl': photoUrl, 'email': s.email,
        });"""
code = code.replace(push_students_old, push_students_new)

# 2. In LoginScreen, add re-enter password controllers and logic
state_vars_old = """  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentPinController = TextEditingController();
  final TextEditingController _studentEmailController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _adminMobileController = TextEditingController();
  final TextEditingController _adminPasswordController =
      TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();"""

state_vars_new = """  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentPinController = TextEditingController();
  final TextEditingController _studentRePinController = TextEditingController();
  final TextEditingController _studentEmailController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _adminMobileController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  
  bool isStudentRePinVisible = false;
"""
code = code.replace(state_vars_old, state_vars_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Patching part 1 complete")
