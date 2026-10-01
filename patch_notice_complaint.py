import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Update Notice creation ID
old_notice_add = '''globalNotices.insert(
                      0,
                      NoticeItem(
                        DateTime.now().toString(),
                        titleCtrl.text,
                        msgCtrl.text,
                        DateTime.now(),
                      ),
                    );'''

new_notice_add = '''globalNotices.insert(
                      0,
                      NoticeItem(
                        DateTime.now().millisecondsSinceEpoch.toString(),
                        titleCtrl.text,
                        msgCtrl.text,
                        DateTime.now(),
                      ),
                    );'''

code = code.replace(old_notice_add, new_notice_add)

# 2. Update Complaint creation ID
old_complaint_add = '''globalComplaints.insert(
                      0,
                      ComplaintItem(
                        DateTime.now().toString(),
                        titleCtrl.text,
                        msgCtrl.text,
                        DateTime.now(),
                        widget.name,
                        widget.roomNo,
                        widget.photo,
                      ),
                    );'''

new_complaint_add = '''globalComplaints.insert(
                      0,
                      ComplaintItem(
                        DateTime.now().millisecondsSinceEpoch.toString(),
                        titleCtrl.text,
                        msgCtrl.text,
                        DateTime.now(),
                        widget.name,
                        widget.roomNo,
                        widget.photo,
                      ),
                    );'''

code = code.replace(old_complaint_add, new_complaint_add)

# 3. Update Student complaint delete button
old_student_del = '''onPressed: () => setState(
                          () => globalStudentHiddenComplaints.add(c.id),
                        ),'''

new_student_del = '''onPressed: () {
                          setState(() {
                            SyncService.deleteComplaint(c.id);
                          });
                        },'''

code = code.replace(old_student_del, new_student_del)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Notices and Complaints patching complete!")
