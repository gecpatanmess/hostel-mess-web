import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // Ensure Admin Notice Delete is also hide-only just in case
  if (!content.contains('Set<String> globalAdminHiddenNotices = {};')) {
    content = content.replaceFirst(
        'Set<String> globalAdminHiddenComplaints = {};', 
        'Set<String> globalAdminHiddenComplaints = {};\nSet<String> globalAdminHiddenNotices = {};'
    );
  }

  // Update Admin Notice Tab
  String oldAdminNoticeTab = '''  Widget _buildNoticeTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: globalNotices.isEmpty
          ? const Center(child: Text("No notices yet. Click + to add one.", style: TextStyle(color: brandGray)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: globalNotices.length,
              itemBuilder: (context, index) {
                final notice = globalNotices[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notice.message, style: const TextStyle(color: brandGray)),
                        const SizedBox(height: 8),
                        Text(formatDateTime(notice.date), style: const TextStyle(fontSize: 11, color: brandOrange, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        setState(() { globalNotices.removeAt(index); });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: brandOrange,
        onPressed: _showAddNoticeDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }''';

  String newAdminNoticeTab = '''  Widget _buildNoticeTab() {
    final visibleNotices = globalNotices.where((n) => !globalAdminHiddenNotices.contains(n.id)).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: visibleNotices.isEmpty
          ? const Center(child: Text("No notices yet. Click + to add one.", style: TextStyle(color: brandGray)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visibleNotices.length,
              itemBuilder: (context, index) {
                final notice = visibleNotices[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notice.message, style: const TextStyle(color: brandGray)),
                        const SizedBox(height: 8),
                        Text(formatDateTime(notice.date), style: const TextStyle(fontSize: 11, color: brandOrange, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        setState(() { globalAdminHiddenNotices.add(notice.id); });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: brandOrange,
        onPressed: _showAddNoticeDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }''';

  if (content.contains('setState(() { globalNotices.removeAt(index); });')) {
    content = content.replaceFirst(oldAdminNoticeTab, newAdminNoticeTab);
  }

  file.writeAsStringSync(content);
}
