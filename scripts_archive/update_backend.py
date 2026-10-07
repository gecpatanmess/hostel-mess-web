import json

try:
    with open('d:/projects/hostel-backend/package.json', 'r', encoding='utf-8') as f:
        pkg = json.load(f)
    
    pkg['version'] = '1.0.29'
    
    with open('d:/projects/hostel-backend/package.json', 'w', encoding='utf-8') as f:
        json.dump(pkg, f, indent=2)
    print("Updated package.json to 1.0.29")
except Exception as e:
    print(f"Error: {e}")
