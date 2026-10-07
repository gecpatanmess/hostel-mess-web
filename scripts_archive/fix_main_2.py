with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final dir = await getApplicationDocumentsDirectory();", "if(kIsWeb) return;\n               final dir = await getApplicationDocumentsDirectory();")

content = content.replace("final dir = await getExternalStorageDirectory();", "if(kIsWeb) return;\n    final dir = await getExternalStorageDirectory();")

content = content.replace("final dir = await getTemporaryDirectory();", "if(kIsWeb) return;\n    final dir = await getTemporaryDirectory();")

# We should also replace the specific instances in init/startup where path_provider is used
# Or just let the generic replace do its job

# Let's verify other issues
# "7. path_provider calls (getTemporaryDirectory(), getExternalStorageDirectory(), getApplicationDocumentsDirectory()) - all need kIsWeb guards."

with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done script 2')
