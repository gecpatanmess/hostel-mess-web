import re
import os

filepath = 'lib/main.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    code = f.read()

old_dialog = """  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "New Complaint",
          style: TextStyle(color: brandDark, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: "Title",
                filled: true,
                fillColor: brandInputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Description",
                filled: true,
                fillColor: brandInputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: brandGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                setState(() {
                  globalComplaints.insert(
                    0,
                    ComplaintItem(
                      DateTime.now().toString(),
                      titleCtrl.text,
                      msgCtrl.text,
                      DateTime.now(),
                      widget.name,
                      widget.roomNo,
                      widget.photoUrl,
                    ),
                  );
                });
                SyncService.pushComplaints();
                Navigator.pop(context);
              }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }"""

new_dialog = """  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String? localComplaintImageUrl;
    bool isUploading = false;
    final ImagePicker _picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateSB) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "New Complaint",
            style: TextStyle(color: brandDark, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: "Title",
                  filled: true,
                  fillColor: brandInputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Description",
                  filled: true,
                  fillColor: brandInputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 40,
                        maxWidth: 800,
                      );
                      if (image != null) {
                        setStateSB(() { isUploading = true; });
                        final bytes = await image.readAsBytes();
                        final url = await SyncService.uploadImage(bytes);
                        setStateSB(() {
                          isUploading = false;
                          if (url != null) {
                            localComplaintImageUrl = url;
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.photo),
                    label: Text(isUploading ? "Uploading..." : "Attach Photo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandInputBg,
                      foregroundColor: brandDark,
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (localComplaintImageUrl != null)
                    const Icon(Icons.check_circle, color: Colors.green)
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: brandGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                  setState(() {
                    globalComplaints.insert(
                      0,
                      ComplaintItem(
                        DateTime.now().toString(),
                        titleCtrl.text,
                        msgCtrl.text,
                        DateTime.now(),
                        widget.name,
                        widget.roomNo,
                        widget.photoUrl,
                        localComplaintImageUrl,
                      ),
                    );
                  });
                  SyncService.pushComplaints();
                  Navigator.pop(context);
                }
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }"""

code = code.replace(old_dialog, new_dialog)

# Now find where the complaint item is displayed in the list and show the image if available
# We will search for formatDateTime(c.date) and insert the image below it.
display_complaint_image = """                        Text(
                          formatDateTime(c.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: brandGray,
                          ),
                        ),
                        if (c.complaintImageUrl != null && c.complaintImageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              c.complaintImageUrl!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          ),
                        ],"""
code = code.replace("""                        Text(
                          formatDateTime(c.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: brandGray,
                          ),
                        ),""", display_complaint_image)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(code)
