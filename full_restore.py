import json
import os
import shutil
import subprocess
import glob

# 1. Restore from Copy
shutil.copy(r'D:\projects\hostelmessmanagment - Copy\lib\main.dart', 'lib/main.dart')
print("Restored from Copy")

# 2. Extract and apply replace_file_content patches from Steps 72-164
transcript_path = r'C:\Users\daxpa\.gemini\antigravity\brain\22369819-24f7-4baa-beb4-c97dbc8bd93f\.system_generated\logs\transcript_full.jsonl'
patches = []
with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        data = json.loads(line)
        step = data.get('step_index', 0)
        if 72 <= step <= 164 and 'tool_calls' in data:
            for tc in data['tool_calls']:
                if tc['name'] == 'replace_file_content':
                    args = tc.get('args', {})
                    if 'main.dart' in args.get('TargetFile', ''):
                        patches.append({
                            'step': step,
                            'summary': args.get('toolSummary'),
                            'target': args.get('TargetContent', ''),
                            'replacement': args.get('ReplacementContent', '')
                        })

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

for p in patches:
    print(f"Applying transcript patch step {p['step']}...")
    if p['target'] in content:
        content = content.replace(p['target'], p['replacement'])
        print(" -> SUCCESS")
    else:
        t2 = p['target'].replace('\r\n', '\n')
        c2 = content.replace('\r\n', '\n')
        if t2 in c2:
            content = c2.replace(t2, p['replacement'].replace('\r\n', '\n'))
            print(" -> SUCCESS (CRLF adjusted)")
        else:
            print(" -> FAILED TO APPLY")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# 3. Run all python scripts in chronological order, EXCEPT the ones from before 29-Sep
# Actually, the file from 29-Sep ALREADY has the effects of scripts run BEFORE 29-Sep!
# So we only run scripts modified AFTER 29-Sep 9:36 PM
scripts = []
for file in glob.glob('*.py'):
    if file in ['test_restore.py', 'test_overlap.py', 'test_strings.py', 'extract.py', 'apply_otp_patches.py', 'print_targets.py', 'apply_otp_manual.py', 'apply_otp_gates.py', 'full_restore.py', 'reconstruct.py', 'run_scripts.py', 'run_scripts_safe2.py']:
        continue
    # only scripts created after Sep 29
    mtime = os.path.getmtime(file)
    # Sep 30 is roughly timestamp 1790000000+, we can just compare it
    # Actually, let's just run them all, since the older scripts might be idempotent or won't match.
    # Wait, if older scripts run, they might corrupt it!
    # Let's filter by time > Sep 30 00:00:00 2026
    # 2026-09-30 00:00:00 is approx 1790649600
    if mtime > 1790649600 and not file.startswith('fix_'):
        scripts.append(file)

scripts.sort(key=lambda x: os.path.getmtime(x))

for script in scripts:
    print(f"Running {script}...")
    try:
        subprocess.run(['python', script], check=True, capture_output=True, text=True)
        print(" -> SUCCESS")
    except subprocess.CalledProcessError as e:
        print(f" -> ERROR in {script}: {e.stderr}")

print("FULL RESTORE COMPLETE!")
