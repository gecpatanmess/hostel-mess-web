import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix the Error:  string interpolation properly because Python raw string might have failed.
text = text.replace("Text('Error: \\')", "Text('Error: ')")
text = text.replace('Text("Error: ")', 'Text("Error: ")')

# Change the error message for 10-digit number not found
old_err = "ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email/number not registered. Please contact Admin.')));"
new_err = "ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Email format')));"
text = text.replace(old_err, new_err)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Code checked and updated.")
