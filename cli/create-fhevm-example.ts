#!/usr/bin/env node

/**
 * create-fhevm-example.ts
 *
 * Automated CLI tool for generating standalone FHEVM example repositories.
 * This script clones the base Hardhat template, inserts specific contracts,
 * generates matching tests, and creates documentation from code annotations.
 *
 * @chapter scaffolding
 * @usage npm run create-example <example-name>
 */

import * as fs from 'fs';
import * as path from 'path';

interface ExampleConfig {
  name: string;
  title: string;
  description: string;
  concept: string;
  learningObjectives: string[];
  fhevmFeatures: string[];
  chapter: string;
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  contractFile: string;
  testFile: string;
  useCaseDescription: string;
}

/**
 * Example configurations for different FHEVM concepts
 */
const EXAMPLES: Record<string, ExampleConfig> = {
  'access-control': {
    name: 'access-control',
    title: 'Access Control for Encrypted Data',
    description: 'Learn how to manage permissions for encrypted data using FHE.allow and FHE.allowThis',
    concept: 'Access Control Lists (ACL) in FHEVM determine who can access encrypted data. This example shows how to grant and manage permissions for encrypted loan amounts in a lending platform.',
    learningObjectives: [
      'Understand FHE.allow() for granting user permissions',
      'Use FHE.allowThis() for contract self-permissions',
      'Implement role-based access patterns',
      'Manage encrypted data visibility'
    ],
    fhevmFeatures: [
      'FHE.allow() - Grant permission to specific address',
      'FHE.allowThis() - Grant permission to contract itself',
      'FHE.allowTransient() - Temporary permissions',
      'euint32 handles - Encrypted 32-bit integers'
    ],
    chapter: 'access-control',
    difficulty: 'beginner',
    contractFile: 'LendingAccessControl.sol',
    testFile: 'AccessControl.test.ts',
    useCaseDescription: 'In a privacy-preserving lending platform, borrowers need to view their own loan amounts while keeping them hidden from others. Access control ensures only authorized parties can decrypt sensitive financial data.'
  },
  'encrypted-arithmetic': {
    name: 'encrypted-arithmetic',
    title: 'Arithmetic Operations on Encrypted Data',
    description: 'Perform calculations on encrypted values without revealing the underlying data',
    concept: 'Fully Homomorphic Encryption allows mathematical operations on encrypted data. This example demonstrates how to calculate interest and total repayment amounts on encrypted loan values.',
    learningObjectives: [
      'Perform FHE.add() for encrypted addition',
      'Use FHE.mul() for encrypted multiplication',
      'Apply FHE.sub() for encrypted subtraction',
      'Handle encrypted arithmetic in real scenarios'
    ],
    fhevmFeatures: [
      'FHE.add() - Encrypted addition',
      'FHE.sub() - Encrypted subtraction',
      'FHE.mul() - Encrypted multiplication',
      'euint32 - Handle encrypted integers',
      'Scalar multiplication with plaintext values'
    ],
    chapter: 'arithmetic',
    difficulty: 'beginner',
    contractFile: 'LendingArithmetic.sol',
    testFile: 'Arithmetic.test.ts',
    useCaseDescription: 'Calculate loan interest and total repayment amounts on encrypted principal values, ensuring borrowers privacy while maintaining accurate financial calculations.'
  },
  'encrypted-comparison': {
    name: 'encrypted-comparison',
    title: 'Comparison Operations on Encrypted Data',
    description: 'Compare encrypted values and make decisions based on encrypted conditions',
    concept: 'FHEVM supports comparison operations that return encrypted boolean results. This example shows how to check if a loan is fully repaid without revealing the actual balance.',
    learningObjectives: [
      'Use FHE.eq() for encrypted equality checks',
      'Work with ebool encrypted boolean type',
      'Implement conditional logic on encrypted data',
      'Handle encrypted comparison results'
    ],
    fhevmFeatures: [
      'FHE.eq() - Encrypted equality comparison',
      'ebool - Encrypted boolean type',
      'FHE.lt() / FHE.gt() - Less than / Greater than',
      'Encrypted conditional branching'
    ],
    chapter: 'comparison',
    difficulty: 'intermediate',
    contractFile: 'LendingComparison.sol',
    testFile: 'Comparison.test.ts',
    useCaseDescription: 'Verify loan repayment status by checking if the encrypted remaining balance equals zero, without exposing the actual balance amount to unauthorized parties.'
  },
  'user-decryption': {
    name: 'user-decryption',
    title: 'User-Specific Decryption Patterns',
    description: 'Enable authorized users to decrypt their own encrypted data',
    concept: 'User decryption allows specific addresses to decrypt encrypted values they are authorized to access. This example demonstrates how borrowers and lenders can decrypt loan details specific to them.',
    learningObjectives: [
      'Implement user-specific decryption',
      'Use access control for decryption authorization',
      'Handle decryption requests securely',
      'Manage multiple authorized decryptors'
    ],
    fhevmFeatures: [
      'User decryption with authorization checks',
      'ACL-based decryption permissions',
      'Multiple decryptor support',
      'Secure key management'
    ],
    chapter: 'decryption',
    difficulty: 'intermediate',
    contractFile: 'LendingUserDecryption.sol',
    testFile: 'UserDecryption.test.ts',
    useCaseDescription: 'Allow borrowers to decrypt their loan amounts and lenders to decrypt details of loans they funded, while maintaining privacy from unauthorized users.'
  },
  'credit-scoring': {
    name: 'credit-scoring',
    title: 'Privacy-Preserving Credit Scoring',
    description: 'Manage encrypted credit scores using euint8 for smaller encrypted values',
    concept: 'Encrypted credit scores protect user financial privacy while enabling risk assessment. This example uses euint8 for efficient storage of 0-100 credit score values.',
    learningObjectives: [
      'Use euint8 for small encrypted integers',
      'Implement credit score updates',
      'Handle encrypted score comparisons',
      'Manage privacy-preserving risk assessment'
    ],
    fhevmFeatures: [
      'euint8 - 8-bit encrypted integers',
      'Efficient encrypted small values',
      'Update encrypted scores',
      'Range-bound encrypted data (0-100)'
    ],
    chapter: 'advanced-patterns',
    difficulty: 'intermediate',
    contractFile: 'LendingCreditScore.sol',
    testFile: 'CreditScore.test.ts',
    useCaseDescription: 'Store and update encrypted credit scores for privacy-preserving loan risk assessment, ensuring users financial history remains confidential.'
  },
  'input-proofs': {
    name: 'input-proofs',
    title: 'Input Proof Validation',
    description: 'Handle encrypted inputs securely with proper validation',
    concept: 'Input proofs ensure encrypted values submitted by users are valid and cannot be manipulated. This example shows proper patterns for accepting encrypted loan amounts.',
    learningObjectives: [
      'Understand input proof requirements',
      'Validate encrypted user inputs',
      'Handle proof verification',
      'Avoid common input handling mistakes'
    ],
    fhevmFeatures: [
      'Input proof validation',
      'Secure encrypted input handling',
      'FHE.asEuint32() for input conversion',
      'Proof verification patterns'
    ],
    chapter: 'security',
    difficulty: 'advanced',
    contractFile: 'LendingInputProofs.sol',
    testFile: 'InputProofs.test.ts',
    useCaseDescription: 'Accept encrypted loan amount requests from users with proper validation, preventing manipulation and ensuring data integrity.'
  }
};

/**
 * Copy directory recursively
 */
function copyDirectory(src: string, dest: string): void {
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }

  const entries = fs.readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      copyDirectory(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

/**
 * Replace template placeholders in README
 */
function generateReadme(config: ExampleConfig, destPath: string): void {
  const templatePath = path.join(__dirname, '../templates/hardhat-base/README.template.md');
  let content = fs.readFileSync(templatePath, 'utf-8');

  const replacements: Record<string, string> = {
    '{{EXAMPLE_TITLE}}': config.title,
    '{{EXAMPLE_DESCRIPTION}}': config.description,
    '{{CONCEPT_EXPLANATION}}': config.concept,
    '{{LEARNING_OBJECTIVES}}': config.learningObjectives.map(obj => `- ${obj}`).join('\n'),
    '{{CONTRACT_DESCRIPTION}}': `This example implements \`${config.contractFile}\`, demonstrating ${config.description.toLowerCase()}.`,
    '{{FHEVM_FEATURES}}': config.fhevmFeatures.map(feat => `- **${feat}**`).join('\n'),
    '{{USAGE_EXAMPLE}}': `See \`test/${config.testFile}\` for detailed usage examples with annotations.`,
    '{{TEST_COVERAGE_POINTS}}': config.learningObjectives.map(obj => `- ${obj}`).join('\n'),
    '{{COMMON_MISTAKES}}': '- Missing FHE.allowThis() before operations\n- Forgetting to grant user permissions with FHE.allow()\n- Incorrect input proof handling',
    '{{BEST_PRACTICES}}': '- Always call FHE.allowThis() for contract operations\n- Grant minimal necessary permissions\n- Use appropriate encrypted type sizes (euint8 vs euint32)',
    '{{USE_CASE}}': config.useCaseDescription,
    '{{NEXT_EXAMPLES}}': '- Advanced access control patterns\n- Multi-party decryption\n- Complex encrypted calculations',
    '{{CHAPTER_TAG}}': config.chapter,
    '{{DIFFICULTY_LEVEL}}': config.difficulty.charAt(0).toUpperCase() + config.difficulty.slice(1)
  };

  for (const [key, value] of Object.entries(replacements)) {
    content = content.replace(new RegExp(key, 'g'), value);
  }

  fs.writeFileSync(destPath, content);
}

/**
 * Update package.json with example name
 */
function updatePackageJson(config: ExampleConfig, destPath: string): void {
  const packageJsonPath = path.join(destPath, 'package.json');
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));

  packageJson.name = `fhevm-example-${config.name}`;
  packageJson.description = config.description;

  fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));
}

/**
 * Create example repository
 */
function createExample(exampleName: string, outputDir?: string): string {
  const config = EXAMPLES[exampleName];

  if (!config) {
    console.error(`❌ Error: Unknown example "${exampleName}"`);
    console.log('\nAvailable examples:');
    Object.keys(EXAMPLES).forEach(name => {
      console.log(`  - ${name}`);
    });
    process.exit(1);
  }

  const baseDir = outputDir || path.join(process.cwd(), 'generated-examples');
  const exampleDir = path.join(baseDir, `example-${config.name}`);

  console.log(`\n🔨 Creating FHEVM example: ${config.title}`);
  console.log(`📁 Output directory: ${exampleDir}\n`);

  // Step 1: Clone base template
  console.log('1️⃣  Cloning base Hardhat template...');
  const templateDir = path.join(__dirname, '../templates/hardhat-base');
  copyDirectory(templateDir, exampleDir);

  // Step 2: Copy example contract
  console.log('2️⃣  Adding example contract...');
  const contractSrc = path.join(__dirname, '../examples', config.name, 'contracts', config.contractFile);
  const contractDest = path.join(exampleDir, 'contracts', config.contractFile);

  if (fs.existsSync(contractSrc)) {
    fs.copyFileSync(contractSrc, contractDest);
  } else {
    console.log(`   ⚠️  Contract file not found: ${contractSrc}`);
  }

  // Step 3: Copy test file
  console.log('3️⃣  Adding test suite...');
  const testSrc = path.join(__dirname, '../examples', config.name, 'test', config.testFile);
  const testDest = path.join(exampleDir, 'test', config.testFile);

  if (fs.existsSync(testSrc)) {
    fs.copyFileSync(testSrc, testDest);
  } else {
    console.log(`   ⚠️  Test file not found: ${testSrc}`);
  }

  // Step 4: Generate README
  console.log('4️⃣  Generating README...');
  const readmePath = path.join(exampleDir, 'README.md');
  generateReadme(config, readmePath);

  // Step 5: Update package.json
  console.log('5️⃣  Updating package.json...');
  updatePackageJson(config, exampleDir);

  console.log('\n✅ Example created successfully!\n');
  console.log('Next steps:');
  console.log(`  cd ${path.relative(process.cwd(), exampleDir)}`);
  console.log('  npm install');
  console.log('  npm test');
  console.log('');

  return exampleDir;
}

/**
 * Main CLI entry point
 */
function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('📚 FHEVM Example Generator\n');
    console.log('Usage: npm run create-example <example-name> [output-dir]\n');
    console.log('Available examples:');

    Object.entries(EXAMPLES).forEach(([name, config]) => {
      console.log(`\n  ${name} (${config.difficulty})`);
      console.log(`    ${config.description}`);
    });

    console.log('');
    return;
  }

  const [exampleName, outputDir] = args;
  createExample(exampleName, outputDir);
}

// Run if called directly
if (require.main === module) {
  main();
}

export { createExample, EXAMPLES, ExampleConfig };
