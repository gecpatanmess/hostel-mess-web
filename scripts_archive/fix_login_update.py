import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target_student = '''  Future<void> _finalizeStudentLogin(String mode, RegisteredStudent student) async {'''
new_student = '''  Future<void> _finalizeStudentLogin(String mode, RegisteredStudent student) async {
    AppUpdateService.checkForUpdate(context);'''
text = text.replace(target_student, new_student)

target_admin = '''  Future<void> _finalizeAdminLogin(String mode, AdminUser admin) async {'''
new_admin = '''  Future<void> _finalizeAdminLogin(String mode, AdminUser admin) async {
    AppUpdateService.checkForUpdate(context);'''
text = text.replace(target_admin, new_admin)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Added checkForUpdate to logins")
