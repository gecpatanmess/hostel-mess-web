
const fs = require('fs');
let lines = fs.readFileSync('lib/main.dart', 'utf-8').split('\n');
for (let i = 0; i < lines.length; i++) {
    if (lines[i] === '    ));' && lines[i+1] === '  }') {
        // Leave the one for _buildAdminsTab intact, which is before _buildAdminHomeTab
        if (lines[i+3] && lines[i+3].includes('_buildAdminHomeTab')) {
            continue;
        }
        lines[i] = '    );';
    }
}
fs.writeFileSync('lib/main.dart', lines.join('\n'));

