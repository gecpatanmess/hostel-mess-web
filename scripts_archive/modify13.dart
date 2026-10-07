import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  String oldHeader = '''          Container(
            color: brandDark,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("Room", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("B", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("L", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("D", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ]
            )
          ),''';

  String newHeader = '''          Container(
            color: brandDark,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("Room", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("B", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("L", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("D", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ]
            )
          ),''';

  String oldRow = '''                return Container(
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(row['room'], style: TextStyle(fontWeight: row['isEmpty'] ? FontWeight.normal : FontWeight.bold, color: row['isEmpty'] ? Colors.grey : brandDark))),
                      Expanded(flex: 3, child: Text(row['name'], style: TextStyle(color: row['isEmpty'] ? Colors.grey : brandDark, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 1, child: buildCell(row['b'])),
                      Expanded(flex: 1, child: buildCell(row['l'])),
                      Expanded(flex: 1, child: buildCell(row['d'])),
                      Expanded(flex: 2, child: Text("₹\${row['total']}", textAlign: TextAlign.right, style: TextStyle(color: row['isEmpty'] ? Colors.grey : (row['total'] > 0 ? brandOrange : brandGray), fontWeight: FontWeight.bold))),
                    ]
                  )
                );''';

  String newRow = '''                String dateStr = "\${selectedDate.day.toString().padLeft(2,'0')}/\${selectedDate.month.toString().padLeft(2,'0')}";
                return Container(
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(row['room'], style: TextStyle(fontWeight: row['isEmpty'] ? FontWeight.normal : FontWeight.bold, color: row['isEmpty'] ? Colors.grey : brandDark))),
                      Expanded(flex: 3, child: Text(row['name'], style: TextStyle(color: row['isEmpty'] ? Colors.grey : brandDark, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 1, child: buildCell(row['b'])),
                      Expanded(flex: 1, child: buildCell(row['l'])),
                      Expanded(flex: 1, child: buildCell(row['d'])),
                      Expanded(flex: 2, child: Text(row['isEmpty'] ? '' : dateStr, style: const TextStyle(color: brandGray, fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text("₹\${row['total']}", textAlign: TextAlign.right, style: TextStyle(color: row['isEmpty'] ? Colors.grey : (row['total'] > 0 ? brandOrange : brandGray), fontWeight: FontWeight.bold))),
                    ]
                  )
                );''';

  content = content.replaceFirst(oldHeader, newHeader);
  content = content.replaceFirst(oldRow, newRow);
  
  file.writeAsStringSync(content);
}
