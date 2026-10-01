import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  String oldSetMenu = '''            ListTile(
              leading: const Icon(Icons.set_meal, color: brandDark),
              title: const Text('Set Menu', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                FilePickerResult? result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                );
                if (result != null && result.files.single.path != null) {
                  setState(() {
                    globalMenuFile = File(result.files.single.path!);
                    globalMenuIsPdf = result.files.single.extension?.toLowerCase() == 'pdf';
                  });
                }
              },
            ),''';
  
  String newSetMenu = '''            ListTile(
              leading: const Icon(Icons.set_meal, color: brandDark),
              title: const Text('Set Menu', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _showSetMenuDialog();
              },
            ),''';

  content = content.replaceFirst(oldSetMenu, newSetMenu);

  String setMenuDialogMethod = '''
  void _showSetMenuDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Set Menu", style: TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (globalMenuFile == null)
                    InkWell(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                        );
                        if (result != null && result.files.single.path != null) {
                          setDialogState(() {
                            globalMenuFile = File(result.files.single.path!);
                            globalMenuIsPdf = result.files.single.extension?.toLowerCase() == 'pdf';
                          });
                          setState((){}); // Update parent dashboard
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: brandInputBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: brandOrange.withOpacity(0.5))
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.add_circle_outline, color: brandOrange, size: 48),
                            SizedBox(height: 8),
                            Text("Upload PDF or Image", style: TextStyle(color: brandGray, fontWeight: FontWeight.w500))
                          ]
                        )
                      )
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: brandInputBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(globalMenuIsPdf ? Icons.picture_as_pdf : Icons.image, color: brandOrange),
                          const SizedBox(width: 12),
                          Expanded(child: Text(globalMenuFile!.path.split(Platform.pathSeparator).last, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              setDialogState(() {
                                globalMenuFile = null;
                                globalMenuIsPdf = false;
                              });
                              setState((){}); // Update parent dashboard
                            },
                          )
                        ],
                      )
                    )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: brandGray))
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {''';

  content = content.replaceFirst('  @override\n  Widget build(BuildContext context) {', setMenuDialogMethod);
  
  // also handle standard carriage returns if the file has \r\n
  if (!content.contains('_showSetMenuDialog')) {
      content = content.replaceFirst('  @override\r\n  Widget build(BuildContext context) {', setMenuDialogMethod);
  }

  file.writeAsStringSync(content);
}
