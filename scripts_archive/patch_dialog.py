import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace _showSetMenuDialog completely
start_idx = code.find("void _showSetMenuDialog() {")
end_idx = code.find("Widget build(BuildContext context) {", start_idx)

if start_idx != -1 and end_idx != -1:
    end_idx = code.rfind("  @override\n", start_idx, end_idx)
    if end_idx == -1:
        end_idx = code.find("  @override", start_idx)

    old_dialog_code = code[start_idx:end_idx]
    
    new_dialog_code = """void _showSetMenuDialog() async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final weekDay = now.weekday;
    final defaultMenu = defaultWeeklyMenu[weekDay] ?? defaultWeeklyMenu[DateTime.monday]!;

    String initialBreakfast = defaultMenu['breakfast']!;
    String initialLunch = defaultMenu['lunch']!;
    String initialDinner = defaultMenu['dinner']!;

    try {
      final snap = await FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        initialBreakfast = data['breakfast'] ?? initialBreakfast;
        initialLunch = data['lunch'] ?? initialLunch;
        initialDinner = data['dinner'] ?? initialDinner;
      }
    } catch(e) {}

    final bfCtrl = TextEditingController(text: initialBreakfast);
    final luCtrl = TextEditingController(text: initialLunch);
    final dnCtrl = TextEditingController(text: initialDinner);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Edit Today's Menu", style: TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: bfCtrl, decoration: const InputDecoration(labelText: "Breakfast", border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: luCtrl, decoration: const InputDecoration(labelText: "Lunch", border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: dnCtrl, decoration: const InputDecoration(labelText: "Dinner", border: OutlineInputBorder())),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text("Photo/PDF Menu (Hidden)", style: TextStyle(fontWeight: FontWeight.bold, color: brandGray)),
                    const SizedBox(height: 8),
                    if (globalMenuUrl == null && globalMenuFile == null && globalMenuUploadBytes == null)
                      InkWell(
                        onTap: () async {
                          FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], withData: true);
                          if (result != null) {
                            final file = result.files.single;
                            if (file.bytes != null || file.path != null) {
                              setDialogState(() {
                                if (kIsWeb || file.path == null) {
                                  globalMenuUploadBytes = file.bytes;
                                  globalMenuFile = null;
                                } else {
                                  globalMenuFile = File(file.path!);
                                  globalMenuUploadBytes = file.bytes;
                                }
                                globalMenuIsPdf = file.extension?.toLowerCase() == 'pdf';
                              });
                              setState(() {});
                              SyncService.pushMenu();
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: brandInputBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: brandOrange.withOpacity(0.5))),
                          child: const Column(
                            children: [
                              Icon(Icons.add_circle_outline, color: brandOrange, size: 32),
                              SizedBox(height: 8),
                              Text("Upload PDF or Image", style: TextStyle(color: brandGray, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: brandInputBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(globalMenuIsPdf ? Icons.picture_as_pdf : Icons.image, color: brandOrange),
                            const SizedBox(width: 8),
                            Expanded(child: Text(globalMenuFile != null ? globalMenuFile!.path.split('/').last.split('\\\\').last : 'Uploaded Menu', maxLines: 2, overflow: TextOverflow.visible)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                setDialogState(() {
                                  globalMenuFile = null;
                                  globalMenuUrl = null;
                                  globalMenuUploadBytes = null;
                                  globalMenuIsPdf = false;
                                });
                                setState(() {});
                                SyncService.pushMenu();
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: brandGray)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandOrange, foregroundColor: Colors.white),
                  onPressed: () async {
                    await FirebaseDatabase.instance.ref('hostelData/daily_menus/$todayStr').set({
                      'breakfast': bfCtrl.text.trim(),
                      'lunch': luCtrl.text.trim(),
                      'dinner': dnCtrl.text.trim(),
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Today's Menu updated!"), backgroundColor: Colors.green));
                    }
                  },
                  child: const Text("Save Menu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

"""
    code = code[:start_idx] + new_dialog_code + code[end_idx:]

    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Patched dialog")
else:
    print("Could not find bounds")
