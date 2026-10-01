import 'dart:io';

void main() {
  File file = File('lib/main.dart');
  String content = file.readAsStringSync();

  // Replace the old sample data map with >22 present days
  String oldData = '''  Map<String, List<String>> sampleDays = {
    '2026-9-1': ['P', 'P', 'P'],   // B, L, D - Full day
    '2026-9-2': ['P', 'P', 'A'],   // Skipped dinner
    '2026-9-3': ['A', 'P', 'P'],   // Skipped breakfast
    '2026-9-4': ['P', 'A', 'A'],   // Only breakfast
    '2026-9-5': ['A', 'A', 'A'],   // Absent full day
    '2026-9-6': ['P', 'P', 'P'],   // Full day
    '2026-9-7': ['P', 'P', 'P'],   // Full day
    '2026-9-8': ['A', 'A', 'A'],   // Absent full day
    '2026-9-9': ['P', 'A', 'P'],   // Skipped lunch
    '2026-9-10': ['P', 'P', 'P'],  // Full day
    '2026-9-11': ['P', 'P', 'A'],  // Skipped dinner
    '2026-9-12': ['A', 'P', 'P'],  // Skipped breakfast
    '2026-9-13': ['P', 'P', 'P'],  // Full day
    '2026-9-14': ['A', 'A', 'A'],  // Absent full day
    '2026-9-15': ['P', 'P', 'P'],  // Full day
    '2026-9-16': ['P', 'A', 'P'],  // Skipped lunch
    '2026-9-17': ['P', 'P', 'P'],  // Full day
    '2026-9-18': ['A', 'P', 'P'],  // Skipped breakfast
    '2026-9-19': ['P', 'P', 'P'],  // Full day
    '2026-9-20': ['P', 'P', 'A'],  // Skipped dinner
    '2026-9-21': ['A', 'A', 'A'],  // Absent full day
    '2026-9-22': ['P', 'P', 'P'],  // Full day
    '2026-9-23': ['P', 'A', 'P'],  // Skipped lunch
    '2026-9-24': ['P', 'P', 'P'],  // Full day
  };''';

  String newData = '''  Map<String, List<String>> sampleDays = {
    '2026-9-1': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-2': ['P', 'P', 'A'],   // Skipped dinner = 80
    '2026-9-3': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-4': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-5': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-6': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-7': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-8': ['A', 'P', 'P'],   // Skipped breakfast = 120
    '2026-9-9': ['P', 'P', 'P'],   // Full day = 140
    '2026-9-10': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-11': ['P', 'P', 'A'],  // Skipped dinner = 80
    '2026-9-12': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-13': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-14': ['A', 'A', 'A'],  // Absent full day = 0
    '2026-9-15': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-16': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-17': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-18': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-19': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-20': ['P', 'A', 'P'],  // Skipped lunch = 80
    '2026-9-21': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-22': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-23': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-24': ['P', 'P', 'P'],  // Full day = 140
    '2026-9-25': ['P', 'P', 'P'],  // Full day = 140
  };''';

  content = content.replaceFirst(oldData, newData);
  file.writeAsStringSync(content);
}
