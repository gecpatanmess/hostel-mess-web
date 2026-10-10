import urllib.request
import json
req = urllib.request.Request('https://hostel-mess-21845-default-rtdb.firebaseio.com/hostelData_boys/students.json')
with urllib.request.urlopen(req) as res:
    data = json.loads(res.read().decode('utf-8'))
    print(data[:2])
