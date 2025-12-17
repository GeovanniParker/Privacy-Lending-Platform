# Developer Guide - FHEVM Examples Hub

**Comprehensive guide for maintaining and extending the FHEVM Examples Hub**

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Adding New Examples](#adding-new-examples)
3. [Updating Dependencies](#updating-dependencies)
4. [CLI Tool Architecture](#cli-tool-architecture)
5. [Testing Guidelines](#testing-guidelines)
6. [Documentation Standards](#documentation-standards)
7. [Common Maintenance Tasks](#common-maintenance-tasks)
8. [Troubleshooting](#troubleshooting)

---

## Project Overview

### Architecture

```
PrivacyLending/
├── cli/                        # Automation tools
│   ├── create-fhevm-example.ts     # Single example generator
│   ├── create-fhevm-category.ts    # Category generator
│   └── generate-docs.ts            # Documentation generator
├── templates/
│   └── hardhat-base/          # Base Hardhat template
├── examples/                   # Example source files
│   ├── fhe-counter/           # Basic counter
│   ├── access-control/        # Access control patterns
│   ├── encrypted-arithmetic/  # FHE arithmetic ops
│   └── ...                    # More examples
└── docs/                      # Generated documentation
```

### Key Technologies

- **Solidity 0.8.24** - Smart contract language
- **Hardhat** - Development environment
- **TypeScript** - CLI tools and tests
- **@fhevm/solidity** - FHEVM library
- **GitBook** - Documentation platform

---

## Adding New Examples

### Step 1: Create Example Structure

```bash
# Create directories
mkdir -p examples/your-example/contracts
mkdir -p examples/your-example/test
```

### Step 2: Write the Contract

Create `examples/your-example/contracts/YourExample.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Your Example Title
/// @notice Brief description
/// @dev Implementation details
/// @chapter your-category
contract YourExample is SepoliaConfig {
    // Implementation
}
```

**Requirements:**
- ✅ Include comprehensive comments
- ✅ Use `@chapter` tag for categorization
- ✅ Demonstrate one clear FHEVM concept
- ✅ Show both correct and incorrect patterns
- ✅ Include real-world use case

### Step 3: Write Tests

Create `examples/your-example/test/YourExample.test.ts`:

```typescript
import { expect } from "chai";
import { ethers } from "hardhat";

/**
 * @title Your Example Tests
 * @notice Test suite description
 * @chapter your-category
 * @difficulty beginner|intermediate|advanced
 */
describe("Your Example", function () {
  // Tests with ✅ and ❌ markers
});
```

**Test Requirements:**
- ✅ Use TSDoc comments
- ✅ Include `@chapter` and `@difficulty` tags
- ✅ Mark positive tests with ✅
- ✅ Mark negative tests with ❌
- ✅ Explain key concepts in comments
- ✅ Cover edge cases

### Step 4: Update CLI Configuration

Edit `cli/create-fhevm-example.ts` and add to `EXAMPLES`:

```typescript
const EXAMPLES: Record<string, ExampleConfig> = {
  // ... existing examples
  'your-example': {
    name: 'your-example',
    title: 'Your Example Title',
    description: 'Brief description',
    concept: 'Detailed explanation of the concept',
    learningObjectives: [
      'First learning objective',
      'Second learning objective',
    ],
    fhevmFeatures: [
      'FHE.operation() - Description',
      'Another feature',
    ],
    chapter: 'your-category',
    difficulty: 'beginner', // or 'intermediate' or 'advanced'
    contractFile: 'YourExample.sol',
    testFile: 'YourExample.test.ts',
    useCaseDescription: 'Real-world use case explanation'
  }
};
```

### Step 5: Test Your Example

```bash
# Generate standalone example
npm run create-example your-example

# Navigate to generated example
cd generated-examples/example-your-example

# Install and test
npm install
npm run compile
npm run test
```

### Step 6: Generate Documentation

```bash
npm run generate-docs
```

---

## Updating Dependencies

### When @fhevm/solidity Updates

1. **Update Base Template**

```bash
cd templates/hardhat-base
npm install @fhevm/solidity@latest
npm run compile
```

2. **Test Existing Examples**

```bash
# Generate and test key examples
npm run create-example access-control
cd generated-examples/example-access-control
npm install && npm test
```

3. **Check for Breaking Changes**

Review the @fhevm/solidity changelog:
- API changes
- New encryption types
- Deprecated functions
- Configuration changes

4. **Update Examples If Needed**

If breaking changes exist:
- Update affected contracts
- Update tests
- Update documentation
- Regenerate all examples

5. **Update Documentation**

```bash
npm run generate-docs
```

### Dependency Update Checklist

- [ ] Update `templates/hardhat-base/package.json`
- [ ] Test compilation of all examples
- [ ] Run test suites
- [ ] Check for deprecation warnings
- [ ] Update README if APIs changed
- [ ] Regenerate documentation
- [ ] Update this guide if needed

---

## CLI Tool Architecture

### create-fhevm-example.ts

**Purpose**: Generate standalone example repositories

**Flow**:
1. Clone base template
2. Copy specific contract file
3. Copy matching test file
4. Generate README from template
5. Update package.json with example name

**Key Functions**:
```typescript
createExample(exampleName, outputDir)  // Main entry point
copyDirectory(src, dest)               // Copy template
generateReadme(config, destPath)       // Create README
updatePackageJson(config, destPath)    // Update package.json
```

### create-fhevm-category.ts

**Purpose**: Generate projects with multiple related examples

**Flow**:
1. Clone base template
2. Copy all contracts from category
3. Copy all matching tests
4. Generate unified README
5. Create comprehensive deployment script

**Categories**:
- `basics` - Fundamental concepts
- `advanced` - Complex patterns
- `lending` - Lending platform examples
- `decryption` - Decryption patterns

### generate-docs.ts

**Purpose**: Create GitBook-compatible documentation

**Flow**:
1. Read example configurations
2. Extract contract source code
3. Extract test annotations
4. Generate markdown files
5. Create SUMMARY.md structure
6. Organize by category

**Output Structure**:
```
docs/
├── README.md
├── SUMMARY.md
└── examples/
    ├── access-control.md
    ├── encrypted-arithmetic.md
    └── ...
```

---

## Testing Guidelines

### Test Structure

```typescript
describe("Contract Name", function () {
  // Setup
  let contract: ContractType;
  let owner: any, user1: any;

  before(async function () {
    // Initialize signers
  });

  beforeEach(async function () {
    // Deploy fresh contract
  });

  describe("Feature Category", function () {
    it("✅ Should do expected behavior", async function () {
      // Positive test
    });

    it("❌ Should prevent invalid operation", async function () {
      // Negative test
    });
  });
});
```

### Best Practices

**✅ DO:**
- Use descriptive test names
- Include both success and failure cases
- Test edge cases
- Verify events are emitted
- Check access control
- Test permission management
- Document expected behavior in comments

**❌ DON'T:**
- Skip error cases
- Test only happy paths
- Forget to clean up state
- Ignore gas optimization
- Leave commented-out code

### Testing Encrypted Values

```typescript
// Create encrypted input
const instances = await createInstances(contractAddress, ethers, signer);
const input = instances.alice.createEncryptedInput(contractAddress, signer.address);
input.add32(value);
const encrypted = await input.encrypt();

// Call contract
await contract.operation(encrypted.handles[0], encrypted.inputProof);

// Decrypt and verify
const result = await contract.getEncryptedResult();
const decrypted = instances.alice.decrypt(contractAddress, result);
expect(decrypted).to.equal(expectedValue);
```

---

## Documentation Standards

### Contract Documentation

Use NatSpec format:

```solidity
/// @title Contract Title
/// @notice User-facing description
/// @dev Technical implementation details
/// @chapter category-name
contract Example {
    /// @notice Function description
    /// @dev Implementation notes
    /// @param paramName Parameter description
    /// @return Description of return value
    function example(uint256 paramName) external returns (uint256) {
        // Implementation
    }
}
```

### Test Documentation

Use TSDoc format:

```typescript
/**
 * @title Test Suite Title
 * @notice Description of what is being tested
 * @chapter category-name
 * @difficulty beginner|intermediate|advanced
 *
 * Key Concepts:
 * - Concept 1
 * - Concept 2
 */
describe("Tests", function () {
  /**
   * @test Feature Description
   * @description Detailed explanation
   */
  it("Should work correctly", async function () {
    // Test implementation
  });
});
```

### Markdown Documentation

**Structure**:
1. Title and description
2. Concept explanation
3. Learning objectives
4. Code examples
5. Use cases
6. Best practices
7. Common pitfalls
8. Next steps

**Formatting**:
- Use code blocks with syntax highlighting
- Include ✅/❌ markers for patterns
- Add warnings with ⚠️
- Link related examples
- Use tables for comparisons

---

## Common Maintenance Tasks

### Regenerate All Examples

```bash
# Clean old examples
rm -rf generated-examples/*

# Regenerate all categories
npm run create-category basics
npm run create-category advanced
npm run create-category lending

# Test each category
for dir in generated-examples/*; do
  cd "$dir"
  npm install && npm test
  cd ../..
done
```

### Update All Documentation

```bash
# Regenerate docs
npm run generate-docs

# Check GitBook structure
cat docs/SUMMARY.md

# Preview locally
cd docs && gitbook serve
```

### Add New Category

1. Create category directory structure
2. Add examples to category
3. Update `create-fhevm-category.ts`
4. Update `generate-docs.ts`
5. Test generation
6. Update README

### Fix Broken Example

1. Identify the issue
2. Update source in `examples/`
3. Update tests if needed
4. Test locally
5. Regenerate example
6. Update documentation

---

## Troubleshooting

### Common Issues

#### Example Generation Fails

**Problem**: CLI tool errors during generation

**Solutions**:
```bash
# Check file paths
ls examples/your-example/

# Verify config in create-fhevm-example.ts
# Ensure contractFile and testFile exist

# Check for typos in example name
```

#### Compilation Errors

**Problem**: Contracts don't compile

**Solutions**:
```bash
# Update Solidity version in hardhat.config.ts
# Check import paths
# Verify @fhevm/solidity version

# Clean and rebuild
npx hardhat clean
npx hardhat compile
```

#### Test Failures

**Problem**: Tests fail after generation

**Solutions**:
```bash
# Check FHEVM setup
# Verify signer initialization
# Check encrypted input creation
# Ensure proper permissions (FHE.allow)

# Enable detailed errors
npx hardhat test --verbose
```

#### Missing Dependencies

**Problem**: Module not found errors

**Solutions**:
```bash
# Install root dependencies
npm install

# Install template dependencies
cd templates/hardhat-base
npm install

# Verify package.json is correct
```

### Debug Mode

Enable verbose logging in CLI tools:

```typescript
// In create-fhevm-example.ts
const DEBUG = true;

function log(...args: any[]) {
  if (DEBUG) console.log('[DEBUG]', ...args);
}
```

---

## Version Control Best Practices

### Commit Messages

Use conventional commits:

```
feat: Add public decryption example
fix: Correct access control in counter
docs: Update developer guide
test: Add edge case tests for arithmetic
refactor: Simplify CLI configuration
```

### Branching Strategy

- `main` - Stable releases
- `develop` - Active development
- `feature/*` - New examples/features
- `fix/*` - Bug fixes

### Before Committing

```bash
# Run all checks
npm run build           # Compile CLI tools
npm run create-example access-control  # Test generation
npm test               # Run tests (if any)

# Verify no secrets
git diff               # Review changes
```

---

## Performance Optimization

### Gas Optimization

**Tips for Examples**:
- Use appropriate uint sizes (euint8 vs euint32)
- Minimize storage operations
- Batch permission grants
- Cache encrypted values when possible

### Build Optimization

**Hardhat Config**:
```typescript
solidity: {
  version: "0.8.24",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,  // Adjust based on usage
    },
  },
}
```

---

## Security Considerations

### Input Validation

Always validate inputs:
```solidity
require(value > 0, "Value must be positive");
require(duration <= MAX_DURATION, "Duration too long");
```

### Access Control

Use modifiers:
```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}
```

### Permission Management

Follow the pattern:
```solidity
FHE.allowThis(encryptedValue);  // Contract permission
FHE.allow(encryptedValue, user); // User permission
```

---

## Resources

### External Documentation

- [FHEVM Docs](https://docs.zama.ai/fhevm)
- [Hardhat Docs](https://hardhat.org/docs)
- [Solidity Docs](https://docs.soliditylang.org/)
- [GitBook Docs](https://docs.gitbook.com/)

### Community

- [Zama Discord](https://discord.com/invite/zama)
- [Zama Community Forum](https://community.zama.ai/)
- [GitHub Issues](https://github.com/zama-ai/fhevm)

---

## Appendix

### Example Checklist

When creating a new example, verify:

- [ ] Contract compiles without errors
- [ ] Tests pass successfully
- [ ] Documentation is comprehensive
- [ ] Example demonstrates one clear concept
- [ ] Both correct and incorrect patterns shown
- [ ] Real-world use case explained
- [ ] CLI configuration added
- [ ] Standalone generation tested
- [ ] GitBook docs generated
- [ ] No prohibited references
- [ ] All content in English

### Release Checklist

Before releasing new version:

- [ ] All examples compile
- [ ] All tests pass
- [ ] Documentation up to date
- [ ] CHANGELOG updated
- [ ] Version bumped in package.json
- [ ] README reflects changes
- [ ] Demo video updated (if major changes)
- [ ] No security vulnerabilities

---

**Last Updated**: December 2025

**Maintainers**: FHEVM Examples Team

**License**: MIT
