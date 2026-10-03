import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    'https://hostel-backend-replace-me.onrender.com', 
    'https://gecpatan-mess.onrender.com'
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("URL updated successfully.")
