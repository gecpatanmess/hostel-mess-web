import sys

with open('web/index.html', 'r', encoding='utf-8') as f:
    text = f.read()

cropper_tags = '''
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.13/cropper.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.13/cropper.min.js"></script>
'''

if 'cropper.css' not in text:
    text = text.replace('</head>', cropper_tags + '\n</head>')

with open('web/index.html', 'w', encoding='utf-8') as f:
    f.write(text)
print("Index.html updated.")
