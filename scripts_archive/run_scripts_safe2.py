import os
import subprocess
import glob

# Get all python scripts created before today? Or just explicitly list them from the transcript
scripts_to_run = [
    "fix.py", "migrate_supabase.py", "patch_push.py", "patch_listen.py",
    "patch_delete.py", "update_manifest.py", "patch_wrapper.py", 
    "patch_notice_complaint.py", "fix_main.py", "fix_main_2.py", 
    "fix_fileimage.py", "fix_bang.py", "fix_decoration.py", "refactor1.py",
    "refactor2.py", "refactor3.py", "refactor4.py", "refactor_final.py",
    "refactor_last.py", "fix_final.py", "patch_part1.py", "patch_part2.py",
    "patch_part3.py", "patch_part4.py", "patch_classes.py", "patch_re_enter.py",
    "patch_tab.py", "patch_state.py", "patch_sync.py", "patch_sync2.py",
    "patch_sync3.py", "patch_admin.py", "patch1.py", "patch2.py", "patch_import.py",
    "check.py", "patch3.py", "patch_basic.py", "patch_login.py", "patch_menu.py",
    "patch_ispdf.py", "patch_daily_menu.py", "patch_dialog.py", "patch_security.py",
    "fix_hash.py", "fix_forgot.py", "patch_menu_ui.py", "update_pubspec.py",
    "patch_ui.py", "patch_drawer_robust.py"
]

print("Restoring backup...")
os.system("copy lib\\main.dart.bak lib\\main.dart")

for script in scripts_to_run:
    if os.path.exists(script):
        print(f"Running {script}...")
        try:
            subprocess.run(["python", script], timeout=30, capture_output=True, text=True)
        except Exception as e:
            print(f"Failed {script}")

print("Done rebuilding!")
