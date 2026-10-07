import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('globalSyncTrigger.value++;')
while idx != -1:
    ctx = content[max(0, idx-500):idx+500]
    if \"data['students']\" in ctx or \"isSyncingIn\" in ctx:
        print(content[max(0, idx-800):idx+500])
        break
    idx = content.find('globalSyncTrigger.value++;', idx + 10)
