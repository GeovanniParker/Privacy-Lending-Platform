# FHEVM Examples Hub - Documentation

Welcome to the **FHEVM Examples Hub** documentation! This comprehensive guide will help you learn privacy-preserving smart contract development using Fully Homomorphic Encryption (FHEVM) by Zama.

---

## What is FHEVM?

**FHEVM (Fully Homomorphic Encryption Virtual Machine)** enables smart contracts to perform computations on encrypted data without ever decrypting it. This revolutionary technology allows:

- 🔒 **Complete Privacy** - Data stays encrypted during all operations
- 🧮 **Encrypted Computations** - Perform arithmetic on encrypted values
- 🛡️ **Granular Access Control** - Control who can decrypt data
- ⚡ **EVM Compatibility** - Works with existing Ethereum tools

---

## What's in This Hub?

This project provides:

### 📚 **9+ Complete Examples**
Step-by-step examples covering all FHEVM concepts:
- Basic operations (counter, encryption)
- Access control patterns
- Encrypted arithmetic and comparisons
- User and public decryption
- Advanced patterns (credit scoring, input validation)

### 🛠️ **Automation Tools**
CLI tools to generate standalone example repositories:
- `create-fhevm-example` - Single example generator
- `create-fhevm-category` - Category-based generator
- `generate-docs` - Documentation generator

### 📖 **Comprehensive Documentation**
- Example walkthroughs with code explanations
- Best practices and anti-patterns
- Developer guide for maintenance
- Real-world use cases

### ✅ **Production-Ready Code**
- All examples from working Privacy Lending Platform
- Comprehensive test suites with TSDoc
- Security patterns and access control
- Gas-optimized implementations

---

## Quick Start

### 1. Install Dependencies

```bash
git clone <repository-url>
cd PrivacyLending
npm install
```

### 2. Generate Your First Example

```bash
# Generate FHE Counter example
npm run create-example fhe-counter

# Navigate to generated example
cd generated-examples/example-fhe-counter

# Install and test
npm install
npm run compile
npm run test
```

### 3. Explore the Code

```solidity
// FHECounter.sol - Simple encrypted counter
euint32 private _count;

function increment(inEuint32 calldata value, bytes calldata proof) external {
    euint32 encrypted = FHE.asEuint32(value, proof);
    _count = FHE.add(_count, encrypted);

    FHE.allowThis(_count);
    FHE.allow(_count, msg.sender);
}
```

---

## Learning Path

### 🎓 Beginner Track

**Start Here if You're New to FHEVM**

1. **[FHE Counter](examples/fhe-counter.md)** (15 min)
   - Basic encrypted operations
   - Permission management
   - Your "Hello World" for FHEVM

2. **[Encrypt Single Value](examples/encrypt-value.md)** (20 min)
   - Different encrypted types
   - Input proof handling
   - Type selection guide

3. **[Access Control](examples/access-control.md)** (25 min)
   - FHE.allow() and FHE.allowThis()
   - Role-based patterns
   - Permission best practices

4. **[Encrypted Arithmetic](examples/encrypted-arithmetic.md)** (30 min)
   - Add, subtract, multiply encrypted values
   - Interest calculations
   - Real-world math on private data

**After Completing Beginner Track:**
- ✅ Understand FHE basics
- ✅ Can create simple encrypted contracts
- ✅ Know permission management
- ✅ Ready for intermediate concepts

---

### 🚀 Intermediate Track

**Continue Here After Beginner Track**

5. **[Encrypted Comparison](examples/encrypted-comparison.md)** (25 min)
   - FHE.eq() for equality
   - ebool type
   - Conditional logic

6. **[User Decryption](examples/user-decryption.md)** (30 min)
   - User-specific decryption
   - Multi-party access
   - Selective disclosure

7. **[Public Decryption](examples/public-decryption.md)** (35 min)
   - Gateway pattern
   - Auction/vote reveals
   - Callback handling

8. **[Credit Scoring](examples/credit-scoring.md)** (30 min)
   - Privacy-preserving scores
   - euint8 optimization
   - Risk assessment patterns

**After Completing Intermediate Track:**
- ✅ Master all FHE operations
- ✅ Handle decryption patterns
- ✅ Build complex private applications
- ✅ Ready for advanced patterns

---

### 🏆 Advanced Track

**For Experienced FHEVM Developers**

9. **[Input Proofs](examples/input-proofs.md)** (40 min)
   - Secure input validation
   - Proof verification
   - Security patterns

10. **[Anti-Patterns Guide](../ANTI_PATTERNS.md)** (45 min)
    - Common mistakes
    - Security pitfalls
    - Optimization errors

11. **[Developer Guide](../DEVELOPER_GUIDE.md)** (60 min)
    - Creating new examples
    - Maintenance workflows
    - Contributing guidelines

---

## Example Overview

### Basic Examples

| Example | Concepts | Difficulty | Time |
|---------|----------|-----------|------|
| [FHE Counter](examples/fhe-counter.md) | Basic FHE ops, permissions | Beginner | 15min |
| [Encrypt Value](examples/encrypt-value.md) | Type selection, input proofs | Beginner | 20min |
| [Access Control](examples/access-control.md) | FHE.allow, FHE.allowThis | Beginner | 25min |
| [Encrypted Arithmetic](examples/encrypted-arithmetic.md) | FHE.add/sub/mul | Beginner | 30min |

### Decryption Patterns

| Example | Concepts | Difficulty | Time |
|---------|----------|-----------|------|
| [User Decryption](examples/user-decryption.md) | User-specific decrypt | Intermediate | 30min |
| [Public Decryption](examples/public-decryption.md) | Gateway pattern | Intermediate | 35min |

### Advanced Patterns

| Example | Concepts | Difficulty | Time |
|---------|----------|-----------|------|
| [Encrypted Comparison](examples/encrypted-comparison.md) | FHE.eq, ebool | Intermediate | 25min |
| [Credit Scoring](examples/credit-scoring.md) | euint8, optimization | Intermediate | 30min |
| [Input Proofs](examples/input-proofs.md) | Security, validation | Advanced | 40min |

---

## Core Concepts

### Encrypted Types

```solidity
euint8   // 0-255        - Ages, percentages, small counters
euint32  // 0-4B         - Balances, amounts, timestamps
euint64  // 0-18T        - Large financial values
ebool    // true/false   - Encrypted boolean results
```

### Permission Model

```solidity
// ✅ Always grant contract permission first
FHE.allowThis(encryptedValue);

// ✅ Then grant user permission
FHE.allow(encryptedValue, user);

// ⚠️ Transient permissions (temporary)
FHE.allowTransient(encryptedValue, temporaryAddress);
```

### FHE Operations

```solidity
// Arithmetic
FHE.add(a, b)    // Encrypted addition
FHE.sub(a, b)    // Encrypted subtraction
FHE.mul(a, b)    // Encrypted multiplication

// Comparisons
FHE.eq(a, b)     // Encrypted equality (returns ebool)
FHE.lt(a, b)     // Less than
FHE.gt(a, b)     // Greater than

// Type conversion
FHE.asEuint32(value)              // Plaintext to encrypted
FHE.asEuint32(input, proof)       // External input with proof
```

---

## Real-World Use Cases

### Privacy-Preserving Lending

**Problem**: Traditional lending exposes sensitive borrower data

**FHEVM Solution**:
```solidity
euint32 encryptedLoanAmount;      // Private loan size
euint8 encryptedCreditScore;       // Private credit score
euint32 encryptedRepayment;        // Private payment history
```

**Benefits**:
- 🔒 Loan amounts stay private
- 📊 Credit scores remain confidential
- 💰 Payment history encrypted
- ✅ Still enables risk assessment

**[See Full Implementation →](examples/access-control.md)**

---

### Blind Auctions

**Problem**: Auction bids visible, enabling front-running

**FHEVM Solution**:
```solidity
mapping(address => euint32) private bids;

function placeBid(inEuint32 calldata amount, bytes calldata proof) external {
    bids[msg.sender] = FHE.asEuint32(amount, proof);
    // Bid stays private until reveal
}
```

**Benefits**:
- 🎯 Fair price discovery
- 🛡️ No front-running
- ✅ Verifiable winner
- 🔓 Reveal when auction ends

---

### Confidential Voting

**Problem**: Transparent votes enable coercion

**FHEVM Solution**:
```solidity
euint32[] private votes;

function vote(inEuint32 calldata choice, bytes calldata proof) external {
    votes.push(FHE.asEuint32(choice, proof));
    // Vote private until tally
}
```

**Benefits**:
- 🗳️ Private vote casting
- 📊 Public verifiable tally
- ✅ Coercion-resistant
- 🔍 Transparent results

---

## Tools & Automation

### CLI Tools

Generate standalone examples in seconds:

```bash
# Single example
npm run create-example fhe-counter

# Full category
npm run create-category basics

# Generate docs
npm run generate-docs
```

Each generated example includes:
- ✅ Complete contract code
- ✅ Comprehensive tests
- ✅ Auto-generated README
- ✅ Hardhat configuration
- ✅ Ready to deploy

**[Learn More About CLI Tools →](../README.md#cli-tools-for-example-generation)**

---

## Best Practices

### ✅ DO

- **Always call FHE.allowThis()** after modifying encrypted state
- **Grant minimal permissions** - only what's needed
- **Use smallest encrypted type** that fits your data
- **Validate inputs** where possible
- **Document permission requirements** clearly

### ❌ DON'T

- **Never forget FHE.allowThis()** - contract needs access too
- **Don't reuse input proofs** - create fresh for each use
- **Don't encrypt public constants** - wastes gas
- **Don't decrypt in view functions** - return encrypted handles
- **Don't trust plaintext inputs** - require proofs

**[See Complete Anti-Patterns Guide →](../ANTI_PATTERNS.md)**

---

## Architecture

### Project Structure

```
PrivacyLending/
├── cli/                    # Automation tools
│   ├── create-fhevm-example.ts
│   ├── create-fhevm-category.ts
│   └── generate-docs.ts
├── examples/               # Example source
│   ├── fhe-counter/
│   ├── access-control/
│   └── ...
├── templates/
│   └── hardhat-base/      # Base template
├── docs/                  # This documentation
└── generated-examples/    # Output directory
```

### Example Structure

Each example contains:
```
example-name/
├── contracts/             # Solidity contracts
├── test/                  # Test suites
├── hardhat.config.ts     # Hardhat config
├── package.json          # Dependencies
└── README.md             # Auto-generated docs
```

---

## Resources

### Official Documentation
- [Zama fhEVM Docs](https://docs.zama.ai/fhevm)
- [Protocol Examples](https://docs.zama.ai/protocol/examples)
- [Hardhat Docs](https://hardhat.org/docs)

### Community
- [Zama Discord](https://discord.com/invite/zama)
- [Community Forum](https://community.zama.ai/)
- [GitHub](https://github.com/zama-ai/fhevm)

### Related Projects
- [FHEVM Hardhat Template](https://github.com/zama-ai/fhevm-hardhat-template)
- [OpenZeppelin Confidential](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts)

---

## Contributing

We welcome contributions! To add a new example:

1. Create contract in `examples/your-example/contracts/`
2. Write tests in `examples/your-example/test/`
3. Update CLI configuration in `cli/create-fhevm-example.ts`
4. Test generation: `npm run create-example your-example`
5. Submit pull request

**[See Developer Guide →](../DEVELOPER_GUIDE.md)**

---

## Support

- **Documentation Issues**: Check this guide and examples
- **Technical Questions**: [Zama Discord](https://discord.com/invite/zama)
- **Bug Reports**: GitHub Issues
- **Feature Requests**: Community Forum

---

## License

MIT License - Free to use and learn from

---

## Acknowledgments

Built for **Zama Bounty Track - December 2025**

Special thanks to:
- Zama team for FHEVM technology
- Hardhat for development tools
- OpenZeppelin for security patterns
- FHEVM community for feedback

---

**Ready to build privacy-preserving applications?**

**[Start with FHE Counter →](examples/fhe-counter.md)**

---

*Last Updated: December 2025*
