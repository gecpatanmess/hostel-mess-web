import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix Dio receiveTimeout/sendTimeout
content = content.replace('dio.options.receiveTimeout = const Duration(seconds: 10);', 'dio.options.receiveTimeout = const Duration(seconds: 45);')
content = content.replace('dio.options.sendTimeout = const Duration(seconds: 10);', 'dio.options.sendTimeout = const Duration(seconds: 45);')

# Fix BaseOptions connectTimeout/receiveTimeout
content = content.replace('connectTimeout: const Duration(seconds: 15),', 'connectTimeout: const Duration(seconds: 45),')
content = content.replace('receiveTimeout: const Duration(seconds: 15),', 'receiveTimeout: const Duration(seconds: 45),')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done timeout")
