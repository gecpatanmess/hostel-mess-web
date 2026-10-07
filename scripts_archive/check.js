
const fs = require("fs");
const lines = fs.readFileSync("lib/main.dart", "utf-8").split("\n");
lines.forEach((line, i) => {
    // regex for any non-ascii character
    if (line.match(/[^\x00-\x7F]/)) {
        console.log(`Line ${i+1}: ${line.trim()}`);
    }
});

