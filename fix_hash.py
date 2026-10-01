with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Fix default admin hash
code = code.replace(
    'c984aed014aec7623a54f0591da07a85fd4b762d68a75e0ac3f3d7a45b6a1e4c',
    '8352700df084ceff932a00aaf54200126408287eb03a8957a762668e3c8750e1'
)

# Fix master reset hash
code = code.replace(
    'e04e0e7bcc1345003115e9e02cdd5b8e16b0db8c8d4a76e6ab48ee52cbda8954',
    'f0ff3b50086e347379ef2f8dbc1227a6949e6cd03123c03ef3f3f7adc8da96be'
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Fixed hashes")
