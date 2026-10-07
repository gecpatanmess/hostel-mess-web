import re

def fix_main_dart(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Fix dummy delete
    content = content.replace(".delete().neq('id', 'dummy');", ".delete().not('id', 'is', null);")
    
    lines = content.split('\n')
    methods_to_await = ['pushAttendance', 'pushPollsNow', 'pushAdmins', 'deleteNotice', 'pushNotices', 'pushMenu', 'pushSwitchesNow', 'deleteComplaint', 'pushComplaints', 'pushPaid', 'pushStudents', 'fetchNow']
    
    for i in range(len(lines)):
        line = lines[i]
        for method in methods_to_await:
            target = f'SyncService.{method}'
            if target in line and 'await' not in line:
                # Prepend await
                lines[i] = lines[i].replace(target, f'await {target}')
                
                # Search backwards for the nearest function declaration
                j = i
                found = False
                while j >= max(0, i - 150):
                    if 'async {' in lines[j] or 'async =>' in lines[j]:
                        found = True
                        break
                    match = re.search(r'\((?:[\w\s,<>]+)?\)\s*\{', lines[j])
                    if match:
                        lines[j] = re.sub(r'(\((?:[\w\s,<>]+)?\))\s*\{', r'\1 async {', lines[j])
                        found = True
                        break
                    
                    # Also check for simple `() =>` or `(val) =>` 
                    match2 = re.search(r'\((?:[\w\s,<>]+)?\)\s*=>', lines[j])
                    if match2:
                        lines[j] = re.sub(r'(\((?:[\w\s,<>]+)?\))\s*=>', r'\1 async =>', lines[j])
                        found = True
                        break

                    j -= 1
                
                if not found:
                    print(f"Warning: Could not find function signature to add async for line {i+1}: {line.strip()}")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write('\n'.join(lines))

if __name__ == '__main__':
    fix_main_dart('lib/main.dart')
