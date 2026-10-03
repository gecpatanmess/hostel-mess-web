import urllib.request
import json
url = "https://whliroffubcqsalxdqfs.supabase.co/rest/v1/app_updates?id=eq.1"
headers = {
    "apikey": "sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe",
    "Authorization": "Bearer sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}
data = json.dumps({
    "version": "1.0.44",
    "apk_url": "https://hostel-mess-web.vercel.app/HostelMess_v1.0.44.apk"
}).encode("utf-8")
try:
    req = urllib.request.Request(url, data=data, headers=headers, method="PATCH")
    response = urllib.request.urlopen(req)
    print("Status:", response.status)
except Exception as e:
    print(f"Error: {e}")
