const fs = require('fs');
let content = fs.readFileSync('lib/main.dart', 'utf-8');
content = content.replace(/\\\$\{/g, '${');
fs.writeFileSync('lib/main.dart', content);
