import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

target_menu = """class ViewMenuTab extends StatelessWidget {
  const ViewMenuTab({super.key});
  @override
  Widget build(BuildContext context) {
    if (globalMenuUrl == null || globalMenuUrl!.isEmpty) {
      return const Center(
        child: Text(
          "No menu uploaded yet.",
          style: TextStyle(color: brandGray),
        ),
      );
    }
    if (globalMenuIsPdf) {
      return SfPdfViewer.network(globalMenuUrl!);
    } else {
      return InteractiveViewer(
        child: Center(
          child: Image.network(
            globalMenuUrl!,
            errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 50, color: brandGray),
          ),
        ),
      );
    }
  }
}"""

replacement_menu = """class ViewMenuTab extends StatelessWidget {
  const ViewMenuTab({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('menu').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No menu uploaded yet.", style: TextStyle(color: brandGray)));
        }
        String imgUrl = snapshot.data!.first['image_url'] ?? '';
        bool isPdf = snapshot.data!.first['is_pdf'] ?? false;
        
        if (imgUrl.isEmpty) {
          return const Center(child: Text("No menu uploaded yet.", style: TextStyle(color: brandGray)));
        }

        if (isPdf) {
          return SfPdfViewer.network(imgUrl);
        } else {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                imgUrl,
                errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 50, color: brandGray),
              ),
            ),
          );
        }
      },
    );
  }
}"""

code = code.replace(target_menu, replacement_menu)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Patched ViewMenuTab")
