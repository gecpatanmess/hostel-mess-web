import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // Fix 1: Add hasAttendance to rows.add
  String oldRowAdd = '''          rows.add({
            'room': room,
            'name': nameToDisplay,
            'b': b, 'l': l, 'd': d,
            'total': total,
            'isEmpty': student == null
          });''';
  String newRowAdd = '''          rows.add({
            'room': room,
            'name': nameToDisplay,
            'b': b, 'l': l, 'd': d,
            'total': total,
            'isEmpty': student == null,
            'hasAttendance': b.isNotEmpty || l.isNotEmpty || d.isNotEmpty
          });''';
          
  // Fix 2: Use hasAttendance for dateStr and Total
  String oldRowUI = '''                      Expanded(flex: 2, child: Text(row['isEmpty'] ? '' : dateStr, style: const TextStyle(color: brandGray, fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text("₹\${row['total']}", textAlign: TextAlign.right, style: TextStyle(color: row['isEmpty'] ? Colors.grey : (row['total'] > 0 ? brandOrange : brandGray), fontWeight: FontWeight.bold))),''';
  
  String newRowUI = '''                      Expanded(flex: 2, child: Text(row['hasAttendance'] ? dateStr : '', style: const TextStyle(color: brandGray, fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text(row['hasAttendance'] ? "₹\${row['total']}" : (row['isEmpty'] ? '' : '-'), textAlign: TextAlign.right, style: TextStyle(color: row['total'] > 0 ? brandOrange : brandGray, fontWeight: FontWeight.bold))),''';

  content = content.replaceFirst(oldRowAdd, newRowAdd);
  content = content.replaceFirst(oldRowUI, newRowUI);

  file.writeAsStringSync(content);
}
