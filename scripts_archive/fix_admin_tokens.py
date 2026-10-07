import sys

with open('lib/notification_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target = """      } else if (userType == 'admin' && identifier != null) {
        String safePhone = identifier.replaceAll(RegExp(r'[.#$\[\]]'), '');
        await FirebaseDatabase.instance.ref('hostelData_${globalHostelMode}/admin/fcmTokens/$safePhone').set(token);
        print("Saved FCM token for admin $identifier");
      }"""

new_target = """      } else if (userType == 'admin' && identifier != null) {
        String safePhone = identifier.replaceAll(RegExp(r'[.#$\[\]]'), '');
        // Save Admin token in BOTH folders so they get notifications from both Boys and Girls
        await FirebaseDatabase.instance.ref('hostelData_boys/admin/fcmTokens/$safePhone').set(token);
        await FirebaseDatabase.instance.ref('hostelData_girls/admin/fcmTokens/$safePhone').set(token);
        print("Saved FCM token for admin $identifier in both sections");
      }"""

if target in text:
    text = text.replace(target, new_target)
    print("SUCCESS: Admin token saving fixed")
else:
    print("WARNING: Admin token target not found")

with open('lib/notification_service.dart', 'w', encoding='utf-8') as f:
    f.write(text)
