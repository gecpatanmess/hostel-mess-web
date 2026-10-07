import glob
import os
import subprocess

scripts = []
for file in glob.glob('*.py'):
    if file in ['test_restore.py', 'test_overlap.py', 'fix_encoding.py', 'test_strings.py', 'reconstruct.py']:
        continue
    scripts.append(file)

scripts.sort(key=lambda x: os.path.getmtime(x))

for script in scripts:
    print(f"Running {script}...")
    try:
        res = subprocess.run(['python', script], capture_output=True, text=True, timeout=5)
        print(f"Stdout: {res.stdout.strip()}")
        if res.stderr:
            print(f"Stderr: {res.stderr.strip()}")
    except subprocess.TimeoutExpired:
        print(f"TIMEOUT: {script}")
    except Exception as e:
        print(f"Error: {e}")

print("Done")
