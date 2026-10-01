with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('e04e0e7bcc1345003115e9e02cdd5b8e16b0db8c8d4a76e6ab48ee52cbda8954', 'f0ff3b50086e347379ef2f8dbc1227a6949e6cd03123c03ef3f3f7adc8da96be')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Hash fixed")
