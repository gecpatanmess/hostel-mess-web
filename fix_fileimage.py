import re
import sys

def process(content):
    # For Student Registration
    # image: FileImage(studentPhoto!),
    content = re.sub(
        r'image:\s*FileImage\((studentPhoto!)\),',
        r'image: (!kIsWeb && studentPhoto != null && studentPhoto!.existsSync()) ? FileImage(studentPhoto!) : null,',
        content
    )
    # For Admin Registration
    content = re.sub(
        r'image:\s*FileImage\((adminPhoto!)\),',
        r'image: (!kIsWeb && adminPhoto != null && adminPhoto!.existsSync()) ? FileImage(adminPhoto!) : null,',
        content
    )
    # For widget.photo!
    content = re.sub(
        r'backgroundImage:\s*FileImage\((widget\.photo!)\),',
        r'backgroundImage: (!kIsWeb && widget.photo != null && widget.photo!.existsSync()) ? FileImage(widget.photo!) : null,',
        content
    )
    return content

if __name__ == '__main__':
    with open('lib/main.dart', 'r', encoding='utf-8') as f:
        data = f.read()
    
    new_data = process(data)
    
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(new_data)
    
    print("Done")
