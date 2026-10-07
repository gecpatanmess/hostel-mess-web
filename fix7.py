with open('d:/projects/hostelmessmanagment/lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

bad_str = """  }

  _firebaseSub = _firebaseSub = _dbRef.onValue.listen((event) async {"""

good_str = """  }

  static void listen() {
    _firebaseSub?.cancel();
    _firebaseSub = _dbRef.onValue.listen((event) async {"""

code = code.replace(bad_str, good_str)
with open('d:/projects/hostelmessmanagment/lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print('Fixed listen()')
