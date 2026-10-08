import requests

db_url = 'https://hostel-mess-21845-default-rtdb.firebaseio.com'

def clear_attendance(mode):
    url = f'{db_url}/hostelData_{mode}/attendance.json'
    print(f'Deleting {url}')
    res = requests.delete(url)
    print(res.status_code, res.text)

clear_attendance('boys')
clear_attendance('girls')
