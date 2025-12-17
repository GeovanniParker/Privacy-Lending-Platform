#!/usr/bin/env node
"use strict";
/**
 * generate-docs.ts
 *
 * Documentation generator for FHEVM examples.
 * Extracts TSDoc annotations from test files and generates GitBook-compatible
 * markdown documentation with code examples and explanations.
 *
 * @chapter documentation
 * @usage npm run generate-docs
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateDocs = generateDocs;
exports.extractDocumentation = extractDocumentation;
exports.generateExampleDoc = generateExampleDoc;
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const create_fhevm_example_1 = require("./create-fhevm-example");
const create_fhevm_category_1 = require("./create-fhevm-category");
/**
 * Extract TSDoc comments and code from test files
 */
function extractDocumentation(testFilePath) {
    if (!fs.existsSync(testFilePath)) {
        return [];
    }
    const content = fs.readFileSync(testFilePath, 'utf-8');
    const sections = [];
    // Extract multi-line comments and associated code
    const commentRegex = /\/\*\*([\s\S]*?)\*\/\s*([\s\S]*?)(?=\/\*\*|$)/g;
    let match;
    while ((match = commentRegex.exec(content)) !== null) {
        const comment = match[1];
        const code = match[2].trim().split('\n').slice(0, 20).join('\n'); // Limit code lines
        // Parse comment for metadata
        const titleMatch = comment.match(/@title\s+(.+)/);
        const chapterMatch = comment.match(/@chapter\s+(.+)/);
        if (titleMatch) {
            sections.push({
                title: titleMatch[1].trim(),
                content: comment.replace(/@\w+\s+.*/g, '').trim(),
                code: code.length > 0 ? code : undefined,
                chapter: chapterMatch ? chapterMatch[1].trim() : 'general'
            });
        }
    }
    return sections;
}
/**
 * Generate documentation for a single example
 */
function generateExampleDoc(config) {
    const testPath = path.join(__dirname, '../examples', config.name, 'test', config.testFile);
    const sections = extractDocumentation(testPath);
    let doc = `# ${config.title}\n\n`;
    doc += `**Chapter**: ${config.chapter} | **Difficulty**: ${config.difficulty}\n\n`;
    doc += `## Overview\n\n${config.description}\n\n`;
    doc += `## Concept\n\n${config.concept}\n\n`;
    doc += `## What You'll Learn\n\n`;
    config.learningObjectives.forEach(obj => {
        doc += `- ${obj}\n`;
    });
    doc += `\n## FHEVM Features\n\n`;
    config.fhevmFeatures.forEach(feat => {
        doc += `- ${feat}\n`;
    });
    doc += `\n## Code Examples\n\n`;
    if (sections.length > 0) {
        sections.forEach((section, idx) => {
            doc += `### ${section.title}\n\n`;
            doc += `${section.content}\n\n`;
            if (section.code) {
                doc += `\`\`\`typescript\n${section.code}\n\`\`\`\n\n`;
            }
        });
    }
    else {
        doc += `See [\`test/${config.testFile}\`](../examples/${config.name}/test/${config.testFile}) for detailed examples.\n\n`;
    }
    doc += `## Use Case\n\n${config.useCaseDescription}\n\n`;
    doc += `## Next Steps\n\n`;
    doc += `- Explore the [full contract implementation](../examples/${config.name}/contracts/${config.contractFile})\n`;
    doc += `- Run the [test suite](../examples/${config.name}/test/${config.testFile})\n`;
    doc += `- Try the interactive demo\n\n`;
    doc += `---\n\n`;
    doc += `[← Back to Examples](./) | [View Source Code →](../examples/${config.name}/)\n`;
    return doc;
}
/**
 * Generate GitBook SUMMARY.md
 */
function generateSummary() {
    let summary = `# Summary\n\n`;
    summary += `## Introduction\n\n`;
    summary += `* [Overview](README.md)\n`;
    summary += `* [Quick Start](quick-start.md)\n`;
    summary += `* [Installation](installation.md)\n\n`;
    // Group examples by chapter
    const byChapter = {};
    Object.values(create_fhevm_example_1.EXAMPLES).forEach(config => {
        if (!byChapter[config.chapter]) {
            byChapter[config.chapter] = [];
        }
        byChapter[config.chapter].push(config);
    });
    // Add each chapter
    Object.entries(byChapter).forEach(([chapter, examples]) => {
        const chapterTitle = chapter.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
        summary += `## ${chapterTitle}\n\n`;
        examples.forEach(config => {
            summary += `* [${config.title}](examples/${config.name}.md)\n`;
        });
        summary += `\n`;
    });
    summary += `## Resources\n\n`;
    summary += `* [API Reference](api-reference.md)\n`;
    summary += `* [Best Practices](best-practices.md)\n`;
    summary += `* [Common Pitfalls](common-pitfalls.md)\n`;
    summary += `* [FAQ](faq.md)\n`;
    return summary;
}
/**
 * Generate overview README for docs
 */
function generateDocsReadme() {
    let readme = `# FHEVM Examples Documentation\n\n`;
    readme += `Welcome to the comprehensive guide for FHEVM (Fully Homomorphic Encryption Virtual Machine) development.\n\n`;
    readme += `## About This Documentation\n\n`;
    readme += `This documentation is automatically generated from working code examples extracted from a real-world privacy-preserving lending platform. Each example includes:\n\n`;
    readme += `- ✅ **Working contract code** with detailed comments\n`;
    readme += `- ✅ **Comprehensive tests** demonstrating usage\n`;
    readme += `- ✅ **Real-world context** from production applications\n`;
    readme += `- ✅ **Best practices** and common pitfalls\n\n`;
    readme += `## Examples by Category\n\n`;
    Object.entries(create_fhevm_category_1.CATEGORIES).forEach(([name, category]) => {
        readme += `### ${category.title}\n\n`;
        readme += `**Difficulty**: ${category.difficulty}\n\n`;
        readme += `${category.description}\n\n`;
        category.examples.forEach(exName => {
            const config = create_fhevm_example_1.EXAMPLES[exName];
            if (config) {
                readme += `- [${config.title}](examples/${config.name}.md) - ${config.description}\n`;
            }
        });
        readme += `\n`;
    });
    readme += `## Learning Path\n\n`;
    readme += `### 🌱 Beginners\n\n`;
    readme += `Start with the basics:\n\n`;
    readme += `1. [Access Control](examples/access-control.md)\n`;
    readme += `2. [Encrypted Arithmetic](examples/encrypted-arithmetic.md)\n`;
    readme += `3. [Encrypted Comparison](examples/encrypted-comparison.md)\n\n`;
    readme += `### 🌿 Intermediate\n\n`;
    readme += `Dive deeper into FHEVM:\n\n`;
    readme += `1. [User Decryption](examples/user-decryption.md)\n`;
    readme += `2. [Credit Scoring](examples/credit-scoring.md)\n\n`;
    readme += `### 🌳 Advanced\n\n`;
    readme += `Master complex patterns:\n\n`;
    readme += `1. [Input Proofs](examples/input-proofs.md)\n`;
    readme += `2. Build your own privacy-preserving application\n\n`;
    readme += `## Quick Start\n\n`;
    readme += `\`\`\`bash\n`;
    readme += `# Clone an example\n`;
    readme += `npm run create-example access-control\n\n`;
    readme += `# Navigate to example\n`;
    readme += `cd generated-examples/example-access-control\n\n`;
    readme += `# Install and test\n`;
    readme += `npm install\n`;
    readme += `npm test\n`;
    readme += `\`\`\`\n\n`;
    readme += `## Resources\n\n`;
    readme += `- [Zama Official Documentation](https://docs.zama.ai/fhevm)\n`;
    readme += `- [Privacy Lending Platform](https://github.com/GeovanniParker/PrivacyLending)\n`;
    readme += `- [FHEVM Examples Hub](../README.md)\n\n`;
    readme += `---\n\n`;
    readme += `**Note**: This documentation is generated from real, tested code. All examples are standalone and ready to run.\n`;
    return readme;
}
/**
 * Generate all documentation
 */
function generateDocs(outputDir) {
    const docsDir = outputDir || path.join(__dirname, '../docs');
    console.log('\n📚 Generating FHEVM Examples Documentation\n');
    // Create docs directory structure
    const examplesDir = path.join(docsDir, 'examples');
    if (!fs.existsSync(examplesDir)) {
        fs.mkdirSync(examplesDir, { recursive: true });
    }
    // Generate README
    console.log('1️⃣  Generating overview README...');
    const readme = generateDocsReadme();
    fs.writeFileSync(path.join(docsDir, 'README.md'), readme);
    // Generate SUMMARY for GitBook
    console.log('2️⃣  Generating GitBook SUMMARY...');
    const summary = generateSummary();
    fs.writeFileSync(path.join(docsDir, 'SUMMARY.md'), summary);
    // Generate documentation for each example
    console.log('3️⃣  Generating example documentation...');
    let exampleCount = 0;
    Object.entries(create_fhevm_example_1.EXAMPLES).forEach(([name, config]) => {
        const doc = generateExampleDoc(config);
        const docPath = path.join(examplesDir, `${name}.md`);
        fs.writeFileSync(docPath, doc);
        exampleCount++;
        console.log(`   ✓ ${config.title}`);
    });
    console.log(`\n✅ Documentation generated successfully!\n`);
    console.log(`📊 Statistics:`);
    console.log(`   - Examples documented: ${exampleCount}`);
    console.log(`   - Categories: ${Object.keys(create_fhevm_category_1.CATEGORIES).length}`);
    console.log(`   - Output directory: ${docsDir}`);
    console.log('');
    console.log('📖 To view with GitBook:');
    console.log(`   cd ${path.relative(process.cwd(), docsDir)}`);
    console.log('   gitbook serve');
    console.log('');
}
/**
 * Main CLI entry point
 */
function main() {
    const args = process.argv.slice(2);
    const outputDir = args[0];
    generateDocs(outputDir);
}
// Run if called directly
if (require.main === module) {
    main();
}
