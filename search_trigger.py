import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('globalSyncTrigger.value++;')
while idx != -1:
    if 'data[\\'students\\']' in content[max(0, idx-500):idx+500] or 'isSyncingIn' in content[max(0, idx-500):idx+500]:
        print(content[max(0, idx-1000):idx+500])
        break
    idx = content.find('globalSyncTrigger.value++;', idx + 10)
