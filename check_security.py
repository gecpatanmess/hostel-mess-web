import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Check for Firebase auth usage
print("Firebase Auth Usage: ", "FirebaseAuth" in content)
print("Supabase Auth Usage: ", "supabase.auth" in content)
