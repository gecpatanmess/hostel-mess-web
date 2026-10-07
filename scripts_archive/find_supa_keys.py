import sys
import io
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Look for Supabase.initialize
match = re.search(r'Supabase\.initialize\(\s*url:\s*\'([^\']+)\',\s*anonKey:\s*\'([^\']+)\'', content)
if match:
    print(f"URL: {match.group(1)}")
    print(f"Key: {match.group(2)}")
else:
    print("Supabase credentials not found")
