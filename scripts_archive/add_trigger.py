import re

with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

methods = [
    'pushPollsNow', 'pushAttendance', 'pushNotices', 'pushComplaints', 
    'pushPaid', 'pushStudents', 'pushAdmins', 'pushMenu', 'pushSwitchesNow'
]

# We want to add globalSyncTrigger.value++; right before the end of the try block in these methods.
# Since it's hard to parse arbitrary try blocks with regex, let's just insert it before catch(e) or inside the try block.

# Wait, easier way:
# For each method, find `try {`, and the corresponding `catch(e) {`.
# Actually, we can just replace `catch(e) {` with `globalSyncTrigger.value++;\n    } catch(e) {` 
# ONLY inside those methods.

# Better yet, let's just do a simple replacement for each method where we find the catch block.

for method in methods:
    # Find method start
    start_idx = content.find(f'static Future<void> {method}')
    if start_idx == -1:
        print(f"Not found: {method}")
        continue
    
    catch_idx = content.find('} catch', start_idx)
    
    if catch_idx != -1:
        # Check if we already inserted
        if 'globalSyncTrigger.value++;' not in content[start_idx:catch_idx]:
            # Insert before catch
            content = content[:catch_idx] + '  globalSyncTrigger.value++;\n    ' + content[catch_idx:]
            print(f"Patched {method}")
        else:
            print(f"Already patched {method}")

with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
