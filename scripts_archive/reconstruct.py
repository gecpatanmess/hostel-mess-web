import glob
import os
import subprocess
import shutil

# Copy original bak
shutil.copy('lib/main.dart.bak', 'lib/main.dart')

# Get all scripts ordered by modification time
scripts = []
for file in glob.glob('*.py'):
    if file in ['test_restore.py', 'test_overlap.py', 'fix_encoding.py', 'test_strings.py']:
        continue
    scripts.append(file)

scripts.sort(key=lambda x: os.path.getmtime(x))

for script in scripts:
    # We must ensure the script uses lib/main.dart
    print(f"Running {script}...")
    try:
        subprocess.run(['python', script], check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"Error in {script}: {e.stderr}")

print("Reconstruction complete.")
