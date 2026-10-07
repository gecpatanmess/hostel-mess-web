import re
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('final verified = await showOtpVerificationDialog(context, email);')
if idx != -1:
    start_idx = max(0, content.rfind('void ', 0, idx))
    if start_idx == 0:
        start_idx = max(0, content.rfind('Future', 0, idx))
    print(content[start_idx:idx+800])
else:
    print("Not found.")
