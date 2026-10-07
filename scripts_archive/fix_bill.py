import re

with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. 6554
content = content.replace(
    'int payable = (p == 0 && a == 0) ? 0 : math.max(actual, 3080);',
    'int payable = (p == 0 && a == 0) ? 0 : calculatePayableBill(actual ~/ 70);'
)

# 2. 7233
content = content.replace(
    'payable = math.max(actual, 3080);',
    'payable = calculatePayableBill(actual ~/ 70);'
)

# 3. 7330
content = content.replace(
    'currentPayable = math.max(currentActual, 3080);',
    'currentPayable = calculatePayableBill(currentActual ~/ 70);'
)

# 4 & 5. 7640 & 7681
content = content.replace(
    'int payable = (p == 0 && a == 0) ? 0 : (actual > 3080 ? actual : 3080);',
    'int payable = (p == 0 && a == 0) ? 0 : calculatePayableBill(p);'
)

with open(r'd:\projects\hostelmessmanagment\lib\main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
