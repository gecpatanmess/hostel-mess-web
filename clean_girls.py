import urllib.request
import json
db_url_girls = 'https://hostel-mess-21845-default-rtdb.firebaseio.com/hostelData_girls/students.json'
try:
    req = urllib.request.Request(db_url_girls)
    with urllib.request.urlopen(req) as res:
        data = json.loads(res.read().decode('utf-8'))
        print("Girls data length:", len(data) if data else 0)
        
    cleaned_data = {}
    if isinstance(data, list):
        items = enumerate(data)
    else:
        items = data.items()
        
    for key, s in items:
        if not s: continue
        cleaned_student = {}
        for k, v in s.items():
            if isinstance(v, str):
                cleaned_student[k] = v.replace('\x00', '').strip()
            else:
                cleaned_student[k] = v
        cleaned_data[str(key)] = cleaned_student
        
    req = urllib.request.Request(db_url_girls, data=json.dumps(cleaned_data).encode('utf-8'), method='PUT')
    req.add_header('Content-Type', 'application/json')
    with urllib.request.urlopen(req) as res:
        print(f"Updated girls - {res.status}")
except Exception as e:
    print(e)
