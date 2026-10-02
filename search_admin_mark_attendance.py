import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('AdminDashboardScreen')
if idx != -1:
    matches = [(m.start(), content[max(0, m.start()-500):m.start()+1000]) for m in __import__('re').finditer(r'SyncService\.pushAttendance', content)]
    for i, (midx, ctx) in enumerate(matches):
        print(f'--- {i} ---')
        print(ctx[:800])
