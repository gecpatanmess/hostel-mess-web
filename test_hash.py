import hashlib

pwd = 'asdfg lkjh zxcvb mn'
print(hashlib.sha256(pwd.encode()).hexdigest())
