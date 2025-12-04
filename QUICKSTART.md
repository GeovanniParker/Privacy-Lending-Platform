# Quick Start Guide

## Installation

```bash
# Install dependencies
npm install

# Build CLI tools
npm run build
```

## Generate Your First Example

```bash
# Generate access control example
npm run create-example access-control

# Navigate to the generated example
cd generated-examples/example-access-control

# Install and run
npm install
npm test
```

## Generate Full Category

```bash
# Generate all basic examples
npm run create-category basics

# Generates:
# - example-access-control
# - example-encrypted-arithmetic
# - example-encrypted-comparison
```

## Generate Documentation

```bash
# Generate GitBook-compatible docs
npm run generate-docs

# Output in docs/ directory
# View with: cd docs && gitbook serve
```

## Available Examples

1. **access-control** - FHE.allow() and FHE.allowThis() patterns
2. **encrypted-arithmetic** - FHE.add(), FHE.sub(), FHE.mul()
3. **encrypted-comparison** - FHE.eq() and ebool usage
4. **user-decryption** - User-specific decryption patterns
5. **credit-scoring** - euint8 for small encrypted values
6. **input-proofs** - Secure encrypted input handling

## CLI Commands

### Create Single Example
```bash
npm run create-example <example-name> [output-dir]
```

### Create Category
```bash
npm run create-category <category-name> [output-dir]
```

### Generate Documentation
```bash
npm run generate-docs [output-dir]
```

## Example Structure

Each generated example contains:
- `contracts/` - Solidity contracts
- `test/` - Comprehensive tests with TSDoc
- `hardhat.config.ts` - Hardhat configuration
- `package.json` - Dependencies
- `README.md` - Auto-generated documentation

## Categories

- **basics** - Foundational FHEVM concepts
- **decryption** - Decryption patterns
- **advanced** - Complex patterns and real-world use cases
- **lending** - Complete lending platform examples

## Real-World Context

All examples extracted from **Privacy-Preserving Lending Platform**:
- Anonymous consumer loans
- Encrypted amounts and balances
- Private credit scoring
- Peer-to-peer lending with full privacy

## Resources

- [Full Documentation](./docs/README.md)
- [Zama fhEVM Docs](https://docs.zama.ai/fhevm)
- [Privacy Lending Platform](../PrivacyLending/)

## Demo Video

See `../PrivacyLending/PrivacyLending.mp4` for complete demonstration.

## Bounty Submission

This project is a submission for **Zama Bounty Track - December 2025**.

Features:
- ✅ Automated scaffolding CLI tools
- ✅ 6+ documented example contracts
- ✅ Comprehensive test suites
- ✅ Documentation auto-generation
- ✅ GitBook-compatible output
- ✅ Real-world use cases

---

**Need Help?** Check [README.md](./README.md) for detailed information.
