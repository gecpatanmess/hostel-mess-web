import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# First, find the GestureDetector in _buildStudentForm()
idx = content.find('onTap: () => _pickImage(true),')
if idx != -1:
    print(content[idx-500:idx+1500])
else:
    print("Not found onTap")
