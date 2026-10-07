import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Let's find where globalAttendanceMap is used in the admin panel
idx = content.find('globalAttendanceMap')
occurrences = []
while idx != -1:
    start = max(0, idx - 150)
    end = min(len(content), idx + 150)
    occurrences.append(content[start:end])
    idx = content.find('globalAttendanceMap', idx + 20)

for i, occ in enumerate(occurrences):
    print(f"\n--- Occurrence {i+1} ---")
    print(occ)
