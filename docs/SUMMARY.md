# FHEVM Examples Hub - Documentation

## Getting Started

* [Introduction](README.md)
* [Quick Start Guide](../QUICKSTART.md)
* [Developer Guide](../DEVELOPER_GUIDE.md)

---

## Basic Examples

**Foundation concepts for FHEVM development**

* [FHE Counter](examples/fhe-counter.md)
  * Basic encrypted counter
  * FHE.add() and FHE.sub() operations
  * Permission management fundamentals
  * Difficulty: Beginner

* [Encrypt Single Value](examples/encrypt-value.md)
  * Working with different encrypted types
  * euint8, euint32, euint64 usage
  * Input proof handling
  * Difficulty: Beginner

* [Access Control](examples/access-control.md)
  * FHE.allow() and FHE.allowThis()
  * Permission management patterns
  * Role-based access control
  * Difficulty: Beginner

* [Encrypted Arithmetic](examples/encrypted-arithmetic.md)
  * FHE.add(), FHE.sub(), FHE.mul()
  * Calculations on encrypted data
  * Interest rate calculations
  * Difficulty: Beginner

* [Encrypted Comparison](examples/encrypted-comparison.md)
  * FHE.eq() for equality checks
  * Working with ebool type
  * Conditional logic on encrypted data
  * Difficulty: Intermediate

---

## Decryption Patterns

**User and public decryption mechanisms**

* [User Decryption](examples/user-decryption.md)
  * User-specific decryption
  * Multi-party access patterns
  * Selective disclosure
  * Difficulty: Intermediate

* [Public Decryption](examples/public-decryption.md)
  * Gateway/relayer pattern
  * Revealing encrypted values publicly
  * Auction and voting reveals
  * Difficulty: Intermediate

---

## Advanced Patterns

**Complex FHEVM implementations**

* [Credit Scoring](examples/credit-scoring.md)
  * Privacy-preserving credit scores
  * euint8 for small values
  * Risk assessment patterns
  * Difficulty: Intermediate

* [Input Proofs](examples/input-proofs.md)
  * Secure input validation
  * Proof verification
  * Preventing manipulation
  * Difficulty: Advanced

---

## Best Practices

* [Anti-Patterns to Avoid](../ANTI_PATTERNS.md)
  * Common mistakes
  * Security pitfalls
  * Gas optimization errors
  * Permission management issues

* [Testing Guidelines](../DEVELOPER_GUIDE.md#testing-guidelines)
  * Writing comprehensive tests
  * Testing encrypted values
  * Edge case coverage

* [Documentation Standards](../DEVELOPER_GUIDE.md#documentation-standards)
  * NatSpec format
  * TSDoc annotations
  * Example documentation

---

## Reference

### Core Concepts

* **Encrypted Types**
  * euint8 (0-255) - Small values, ages, percentages
  * euint32 (0-4B) - Balances, amounts, timestamps
  * euint64 (0-18T) - Large financial values
  * ebool - Encrypted boolean results

* **Permission Management**
  * FHE.allow() - Grant user permission
  * FHE.allowThis() - Grant contract permission
  * FHE.allowTransient() - Temporary permissions

* **FHE Operations**
  * FHE.add() - Encrypted addition
  * FHE.sub() - Encrypted subtraction
  * FHE.mul() - Encrypted multiplication
  * FHE.eq() - Encrypted equality check
  * FHE.lt() / FHE.gt() - Encrypted comparisons

### Real-World Use Cases

* **Privacy-Preserving Lending**
  * Encrypted loan amounts
  * Private credit scores
  * Confidential repayment tracking
  * Anonymous peer-to-peer lending

* **Blind Auctions**
  * Hidden bids
  * Winner revelation
  * Fair price discovery

* **Confidential Voting**
  * Private vote casting
  * Public tally
  * Verifiable results

---

## Tools & Automation

* [CLI Tools Overview](../README.md#cli-tools-for-example-generation)
* [Creating Examples](../DEVELOPER_GUIDE.md#adding-new-examples)
* [Generating Documentation](../DEVELOPER_GUIDE.md#documentation-standards)

### Automation Scripts

* **create-fhevm-example.ts**
  * Generate standalone example repositories
  * Custom README generation
  * Package configuration

* **create-fhevm-category.ts**
  * Generate category-based projects
  * Multiple related examples
  * Unified documentation

* **generate-docs.ts**
  * Extract code annotations
  * Create GitBook documentation
  * SUMMARY.md generation

---

## Maintenance

* [Updating Dependencies](../DEVELOPER_GUIDE.md#updating-dependencies)
* [Adding New Examples](../DEVELOPER_GUIDE.md#adding-new-examples)
* [Common Tasks](../DEVELOPER_GUIDE.md#common-maintenance-tasks)
* [Troubleshooting](../DEVELOPER_GUIDE.md#troubleshooting)

---

## Resources

### Official Documentation

* [Zama fhEVM Documentation](https://docs.zama.ai/fhevm)
* [Protocol Examples](https://docs.zama.ai/protocol/examples)
* [Hardhat Documentation](https://hardhat.org/docs)
* [Solidity Documentation](https://docs.soliditylang.org/)

### Community

* [Zama Discord](https://discord.com/invite/zama)
* [Zama Community Forum](https://community.zama.ai/)
* [GitHub Repository](https://github.com/zama-ai/fhevm)

### Additional Examples

* [FHEVM Hardhat Template](https://github.com/zama-ai/fhevm-hardhat-template)
* [dApps Repository](https://github.com/zama-ai/dapps)
* [OpenZeppelin Confidential Contracts](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts)

---

## About This Project

**Privacy Lending Platform - FHEVM Examples Hub**

A comprehensive system for creating standalone FHEVM example repositories with automated documentation generation. Built for the Zama Bounty Track - December 2025.

**Features:**
* ✅ 9+ Complete FHEVM Examples
* ✅ 3 Automation CLI Tools
* ✅ GitBook-Compatible Documentation
* ✅ Production-Ready Patterns
* ✅ Comprehensive Test Suites
* ✅ Real-World Use Cases

**License:** MIT

---

## Contributing

Contributions welcome! See [Developer Guide](../DEVELOPER_GUIDE.md) for:
* Adding new examples
* Writing tests
* Documentation standards
* Code review process

---

**Built with ❤️ using FHEVM by Zama**
