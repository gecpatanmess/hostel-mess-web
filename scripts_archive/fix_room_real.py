import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace(
    'Text("Room: ", style: const TextStyle(fontSize: 14, color: brandGray)),',
    'Text("Room: ${_matchedStudent!.roomNo}", style: const TextStyle(fontSize: 14, color: brandGray)),'
)

text = text.replace(
    'hasSavedStudent ? "Room: " : "",',
    'hasSavedStudent ? "Room: ${savedStudentRoom ?? \'Unknown\'}" : "",'
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Room bug REALLY fixed.")
