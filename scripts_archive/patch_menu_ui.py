import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Update ViewMenuTab constructor
old_constructor = """class ViewMenuTab extends StatefulWidget {
  const ViewMenuTab({super.key});"""

new_constructor = """class ViewMenuTab extends StatefulWidget {
  final VoidCallback? onEditMenu;
  const ViewMenuTab({super.key, this.onEditMenu});"""
code = code.replace(old_constructor, new_constructor)

# 2. Update StudentView instantiation
# Find `ViewMenuTab()` in Student Dashboard
code = code.replace("ViewMenuTab(),", "ViewMenuTab(onEditMenu: null),")
code = code.replace("ViewMenuTab() :", "ViewMenuTab(onEditMenu: _showSetMenuDialog) :")

# 3. Update the UI to show Date + Day and the Edit button
old_ui = """Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text("Today: $dayName", style: const TextStyle(color: brandOrange, fontWeight: FontWeight.bold, fontSize: 16)),
              ),"""

new_ui = """Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text("$dayName | ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}", style: const TextStyle(color: brandOrange, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  if (widget.onEditMenu != null)
                    ElevatedButton.icon(
                      onPressed: widget.onEditMenu,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Edit Menu"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                      ),
                    ),
                ],
              ),"""
code = code.replace(old_ui, new_ui)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Patched ViewMenuTab")
