import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target = """                  NotificationService.sendPushNotificationToAdmins(
                    "New Complaint: ${titleCtrl.text}",
                    "${widget.name} (${widget.roomNo}) has submitted a complaint."
                  );"""

new_target = """                  NotificationService.sendPushNotificationToAdmins(
                    "New Complaint (${globalHostelMode.toUpperCase()}): ${titleCtrl.text}",
                    "${widget.name} (${widget.roomNo}) has submitted a complaint."
                  );"""

if target in text:
    text = text.replace(target, new_target)
    print("SUCCESS: Complaint notification fixed")
else:
    print("WARNING: Complaint notification target not found")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
