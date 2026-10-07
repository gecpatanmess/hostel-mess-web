import urllib.request
import json
url = "https://whliroffubcqsalxdqfs.supabase.co/rest/v1/app_updates?id=eq.1"
headers = {
    "apikey": "sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe",
    "Authorization": "Bearer sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe"
}
try:
    req = urllib.request.Request(url, headers=headers)
    response = urllib.request.urlopen(req)
    data = json.loads(response.read().decode('utf-8'))
    print(data)
except Exception as e:
    print(f"Error: {e}")
