import hashlib

def h(t): return hashlib.sha256(t.encode()).hexdigest()

tests = ["admin", "password", "master", "reset", "123456", "12345678", "admin123", "mdhk", "mdhk123", "123456789", "asdfghjk", "asdfghjkl", "hostel", "hostel123", "mdhktensors", "vishal123", "vishal", "mdhk2024"]

target = "e04e0e7bcc1345003115e9e02cdd5b8e16b0db8c8d4a76e6ab48ee52cbda8954"
for t in tests:
    if h(t) == target:
        print(f"Found: {t}")
        exit(0)
print("Not found in common list.")
