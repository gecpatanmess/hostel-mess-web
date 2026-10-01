import json
try:
    with open('d:/projects/hostel-backend/package.json', 'r', encoding='utf-8') as f:
        pkg = json.load(f)
    pkg['version'] = '1.0.30'
    with open('d:/projects/hostel-backend/package.json', 'w', encoding='utf-8') as f:
        json.dump(pkg, f, indent=2)
except Exception as e:
    pass
