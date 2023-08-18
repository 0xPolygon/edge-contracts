const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '../../../../contracts/child/validator/legacy-compat/@openzeppelin');
const secondLineComparisonDir = path.join(__dirname, '../../../../node_modules/@openzeppelin');

function readSecondLine(filePath) {
    const data = fs.readFileSync(filePath, 'utf-8');
    const lines = data.trim().split('\n');
    if (lines.length >= 2) {
        return lines[1];
    }
    return null;
}

function compareSecondLines(file1, file2) {
    const secondLine1 = readSecondLine(file1);
    const secondLine2 = readSecondLine(file2);
    return secondLine1 === secondLine2;
}

function processDirectory(directoryPath) {
    const files = fs.readdirSync(directoryPath);

    const nonMatchingFiles = [];

    files.forEach(file => {
        const filePath1 = path.join(directoryPath, file);
        const filePath2 = path.join(secondLineComparisonDir, path.relative(baseDir, directoryPath), file);

        const stats = fs.statSync(filePath1);
        if (stats.isDirectory()) {
            nonMatchingFiles.push(...processDirectory(filePath1));
        } else {
            if (path.extname(file) === '.sol' && (!fs.existsSync(filePath2) || !compareSecondLines(filePath1, filePath2))) {
                nonMatchingFiles.push({ file });
            }
        }
    });

    return nonMatchingFiles;
}

const nonMatchingFiles = processDirectory(baseDir);

if (nonMatchingFiles.length === 0) {
    console.log('All modified OpenZeppelin contracts up-to-date.');
} else {
    console.log('Outdated modified OpenZeppelin contracts found:');
    nonMatchingFiles.forEach(({ file }) => {
        console.log(`- ${file}`);
    });
}