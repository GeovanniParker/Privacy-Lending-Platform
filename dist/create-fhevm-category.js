#!/usr/bin/env node
"use strict";
/**
 * create-fhevm-category.ts
 *
 * Generates multiple related FHEVM examples as a category.
 * Creates a parent directory and generates all examples within that category.
 *
 * @chapter scaffolding
 * @usage npm run create-category <category-name>
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
exports.CATEGORIES = void 0;
exports.createCategory = createCategory;
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const create_fhevm_example_1 = require("./create-fhevm-example");
/**
 * Category definitions grouping related examples
 */
const CATEGORIES = {
    'basics': {
        name: 'basics',
        title: 'FHEVM Basics',
        description: 'Foundational concepts for working with encrypted data',
        examples: ['access-control', 'encrypted-arithmetic', 'encrypted-comparison'],
        difficulty: 'Beginner',
        overview: `This category covers the fundamental concepts of FHEVM development:

- **Access Control**: Learn how to manage permissions for encrypted data
- **Encrypted Arithmetic**: Perform calculations on encrypted values
- **Encrypted Comparison**: Compare encrypted data and make decisions

These examples provide the building blocks for privacy-preserving smart contracts.`
    },
    'decryption': {
        name: 'decryption',
        title: 'Decryption Patterns',
        description: 'Techniques for securely decrypting encrypted data',
        examples: ['user-decryption'],
        difficulty: 'Intermediate',
        overview: `Master the art of decrypting encrypted data securely:

- **User Decryption**: Allow authorized users to decrypt their own data
- **Multi-Party Decryption**: Coordinate decryption among multiple parties
- **Threshold Decryption**: Require multiple keys to decrypt

Learn when and how to reveal encrypted information safely.`
    },
    'advanced': {
        name: 'advanced',
        title: 'Advanced FHEVM Patterns',
        description: 'Complex patterns and real-world applications',
        examples: ['credit-scoring', 'input-proofs'],
        difficulty: 'Advanced',
        overview: `Explore sophisticated FHEVM patterns for production systems:

- **Credit Scoring**: Privacy-preserving risk assessment
- **Input Proofs**: Secure validation of encrypted inputs
- **Complex Calculations**: Multi-step encrypted operations

These examples demonstrate production-ready patterns from real applications.`
    },
    'lending': {
        name: 'lending',
        title: 'Privacy-Preserving Lending',
        description: 'Complete lending platform examples with FHEVM',
        examples: ['access-control', 'encrypted-arithmetic', 'user-decryption', 'credit-scoring'],
        difficulty: 'Mixed',
        overview: `Build a complete privacy-preserving lending platform:

This category combines multiple FHEVM concepts to create a real-world application
where borrowers and lenders can transact without revealing sensitive financial information.

Learn how to:
- Accept encrypted loan requests
- Calculate interest on encrypted amounts
- Manage permissions for borrowers and lenders
- Implement private credit scoring
- Track encrypted loan balances`
    }
};
exports.CATEGORIES = CATEGORIES;
/**
 * Generate category README
 */
function generateCategoryReadme(config, destPath) {
    const exampleLinks = config.examples.map(exName => {
        const exConfig = create_fhevm_example_1.EXAMPLES[exName];
        if (!exConfig)
            return '';
        return `### [${exConfig.title}](./example-${exName}/)

**Difficulty**: ${exConfig.difficulty.charAt(0).toUpperCase() + exConfig.difficulty.slice(1)}

${exConfig.description}

**Learn**:
${exConfig.learningObjectives.map(obj => `- ${obj}`).join('\n')}

[View Example →](./example-${exName}/)

---
`;
    }).join('\n');
    const content = `# ${config.title}

**${config.description}**

## Overview

${config.overview}

## Examples in This Category

${exampleLinks}

## Getting Started

Each example is a standalone Hardhat project:

\`\`\`bash
# Navigate to an example
cd example-access-control

# Install dependencies
npm install

# Run tests
npm test

# Compile contracts
npm run compile
\`\`\`

## Learning Path

${config.difficulty === 'Beginner' ? 'Start here if you\'re new to FHEVM!' :
        config.difficulty === 'Mixed' ? 'Follow the examples in order for best learning experience.' :
            'Prerequisites: Complete basics category first.'}

${config.examples.map((ex, idx) => `${idx + 1}. ${create_fhevm_example_1.EXAMPLES[ex]?.title || ex}`).join('\n')}

## Real-World Application

These examples are extracted from a production **Privacy-Preserving Lending Platform**:

- 🔒 **Complete Privacy**: All loan amounts encrypted
- 💰 **Peer-to-Peer**: Direct lending without intermediaries
- 🛡️ **Access Control**: Granular permissions for encrypted data
- 📊 **Credit Scoring**: Private risk assessment

[View Full Platform →](https://github.com/GeovanniParker/PrivacyLending)

## Resources

- [Zama fhEVM Documentation](https://docs.zama.ai/fhevm)
- [FHEVM Examples Hub](../)
- [Privacy Lending Demo Video](../../PrivacyLending/PrivacyLending.mp4)

## Next Steps

After completing this category, explore:

${config.difficulty === 'Beginner' ? '- Intermediate: Decryption Patterns\n- Advanced: Complex FHEVM Patterns' :
        config.difficulty === 'Intermediate' ? '- Advanced: Complex FHEVM Patterns\n- Lending: Complete Application' :
            '- Build your own privacy-preserving application!\n- Contribute examples back to the community'}

---

**Chapter**: ${config.name}

**Difficulty**: ${config.difficulty}
`;
    fs.writeFileSync(destPath, content);
}
/**
 * Create category with all examples
 */
function createCategory(categoryName, outputDir) {
    const config = CATEGORIES[categoryName];
    if (!config) {
        console.error(`❌ Error: Unknown category "${categoryName}"`);
        console.log('\nAvailable categories:');
        Object.keys(CATEGORIES).forEach(name => {
            console.log(`  - ${name}`);
        });
        process.exit(1);
    }
    const baseDir = outputDir || path.join(process.cwd(), 'generated-categories');
    const categoryDir = path.join(baseDir, `category-${config.name}`);
    console.log(`\n📚 Creating FHEVM category: ${config.title}`);
    console.log(`📁 Output directory: ${categoryDir}\n`);
    // Create category directory
    if (!fs.existsSync(categoryDir)) {
        fs.mkdirSync(categoryDir, { recursive: true });
    }
    // Generate each example in the category
    config.examples.forEach((exampleName, idx) => {
        console.log(`\n[${idx + 1}/${config.examples.length}] Generating ${exampleName}...`);
        const examplePath = (0, create_fhevm_example_1.createExample)(exampleName, categoryDir);
        console.log(`   ✓ Created ${path.relative(categoryDir, examplePath)}`);
    });
    // Generate category README
    console.log('\n📝 Generating category README...');
    const readmePath = path.join(categoryDir, 'README.md');
    generateCategoryReadme(config, readmePath);
    console.log('\n✅ Category created successfully!\n');
    console.log('📖 Structure:');
    console.log(`   ${config.name}/`);
    console.log('   ├── README.md');
    config.examples.forEach(ex => {
        console.log(`   └── example-${ex}/`);
    });
    console.log('\nNext steps:');
    console.log(`  cd ${path.relative(process.cwd(), categoryDir)}`);
    console.log('  # Navigate to each example and run npm install');
    console.log('');
    return categoryDir;
}
/**
 * Main CLI entry point
 */
function main() {
    const args = process.argv.slice(2);
    if (args.length === 0) {
        console.log('📚 FHEVM Category Generator\n');
        console.log('Usage: npm run create-category <category-name> [output-dir]\n');
        console.log('Available categories:');
        Object.entries(CATEGORIES).forEach(([name, config]) => {
            console.log(`\n  ${name} (${config.difficulty})`);
            console.log(`    ${config.description}`);
            console.log(`    Examples: ${config.examples.length}`);
        });
        console.log('');
        return;
    }
    const [categoryName, outputDir] = args;
    createCategory(categoryName, outputDir);
}
// Run if called directly
if (require.main === module) {
    main();
}
