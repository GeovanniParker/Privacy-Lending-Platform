# FHEVM Anti-Patterns - Common Mistakes to Avoid

**A comprehensive guide to common pitfalls in FHEVM development and how to avoid them**

---

## Table of Contents

1. [Access Control Mistakes](#access-control-mistakes)
2. [Input Proof Errors](#input-proof-errors)
3. [View Function Pitfalls](#view-function-pitfalls)
4. [Permission Management Issues](#permission-management-issues)
5. [Encryption Type Misuse](#encryption-type-misuse)
6. [Handle Lifecycle Errors](#handle-lifecycle-errors)
7. [Gas Optimization Mistakes](#gas-optimization-mistakes)
8. [Security Vulnerabilities](#security-vulnerabilities)

---

## Access Control Mistakes

### ❌ Anti-Pattern 1: Missing FHE.allowThis()

**Wrong**:
```solidity
function storeValue(inEuint32 calldata value, bytes calldata proof) external {
    euint32 encrypted = FHE.asEuint32(value, proof);
    storedValue = encrypted;

    // ❌ Missing FHE.allowThis() - contract can't access its own value!
    FHE.allow(storedValue, msg.sender);
}
```

**Correct**:
```solidity
function storeValue(inEuint32 calldata value, bytes calldata proof) external {
    euint32 encrypted = FHE.asEuint32(value, proof);
    storedValue = encrypted;

    // ✅ Grant contract permission first
    FHE.allowThis(storedValue);
    // ✅ Then grant user permission
    FHE.allow(storedValue, msg.sender);
}
```

**Why**: The contract must have permission to operate on encrypted values it stores. Always call `FHE.allowThis()` after modifying encrypted state.

**Error Symptoms**:
- Contract operations fail silently
- Cannot perform arithmetic on stored values
- Unexpected zero results

---

### ❌ Anti-Pattern 2: Granting Permissions in Wrong Order

**Wrong**:
```solidity
function updateBalance(inEuint32 calldata amount, bytes calldata proof) external {
    euint32 encrypted = FHE.asEuint32(amount, proof);

    // ❌ Granting user permission before storing
    FHE.allow(encrypted, msg.sender);

    balance = FHE.add(balance, encrypted);

    // ❌ Missing allowThis on new result
}
```

**Correct**:
```solidity
function updateBalance(inEuint32 calldata amount, bytes calldata proof) external {
    euint32 encrypted = FHE.asEuint32(amount, proof);

    // ✅ Perform operations first
    balance = FHE.add(balance, encrypted);

    // ✅ Grant permissions on final result
    FHE.allowThis(balance);
    FHE.allow(balance, msg.sender);
}
```

**Why**: Grant permissions on the final result after all operations. Intermediate values don't need permissions.

---

### ❌ Anti-Pattern 3: Forgetting to Grant User Access

**Wrong**:
```solidity
function calculateInterest() external {
    euint32 interest = FHE.mul(loanAmount, FHE.asEuint32(interestRate));
    totalOwed = FHE.add(loanAmount, interest);

    // ❌ User can't decrypt their total owed amount
    FHE.allowThis(totalOwed);
}
```

**Correct**:
```solidity
function calculateInterest() external {
    euint32 interest = FHE.mul(loanAmount, FHE.asEuint32(interestRate));
    totalOwed = FHE.add(loanAmount, interest);

    // ✅ Allow contract to use value
    FHE.allowThis(totalOwed);
    // ✅ Allow user to decrypt their own data
    FHE.allow(totalOwed, msg.sender);
}
```

**Why**: Users need explicit permission to decrypt values, even if the data belongs to them.

---

## Input Proof Errors

### ❌ Anti-Pattern 4: Mismatched Signer and Caller

**Wrong**:
```solidity
// Client-side (Alice creates input)
const input = fhevm.createEncryptedInput(contractAddr, alice.address);
input.add32(100);
const enc = await input.encrypt();

// ❌ Bob tries to submit Alice's encrypted input
await contract.connect(bob).deposit(enc.handles[0], enc.inputProof);
```

**Correct**:
```solidity
// Client-side
const input = fhevm.createEncryptedInput(contractAddr, alice.address);
input.add32(100);
const enc = await input.encrypt();

// ✅ Alice submits her own encrypted input
await contract.connect(alice).deposit(enc.handles[0], enc.inputProof);
```

**Why**: Input proofs are bound to the signer's address. Only the signer who created the proof can submit it.

**Error Message**: `"Input proof verification failed"`

---

### ❌ Anti-Pattern 5: Reusing Input Proofs

**Wrong**:
```solidity
const input = fhevm.createEncryptedInput(contractAddr, user.address);
input.add32(50);
const enc = await input.encrypt();

// ❌ Trying to reuse the same proof twice
await contract.deposit(enc.handles[0], enc.inputProof);
await contract.deposit(enc.handles[0], enc.inputProof); // Fails!
```

**Correct**:
```solidity
// ✅ Create new proof for each submission
const input1 = fhevm.createEncryptedInput(contractAddr, user.address);
input1.add32(50);
const enc1 = await input1.encrypt();
await contract.deposit(enc1.handles[0], enc1.inputProof);

// ✅ New proof for second deposit
const input2 = fhevm.createEncryptedInput(contractAddr, user.address);
input2.add32(50);
const enc2 = await input2.encrypt();
await contract.deposit(enc2.handles[0], enc2.inputProof);
```

**Why**: Each encrypted input requires a fresh proof. Proofs cannot be reused.

---

### ❌ Anti-Pattern 6: Missing Input Proof Parameter

**Wrong**:
```solidity
function deposit(inEuint32 calldata amount) external {
    // ❌ No proof parameter - can't verify input
    euint32 encrypted = FHE.asEuint32(amount);
    balance = FHE.add(balance, encrypted);
}
```

**Correct**:
```solidity
function deposit(inEuint32 calldata amount, bytes calldata inputProof) external {
    // ✅ Include proof for verification
    euint32 encrypted = FHE.asEuint32(amount, inputProof);
    balance = FHE.add(balance, encrypted);

    FHE.allowThis(balance);
    FHE.allow(balance, msg.sender);
}
```

**Why**: Input proofs are required to verify that encrypted inputs are valid and correctly bound.

---

## View Function Pitfalls

### ❌ Anti-Pattern 7: Using View Functions with Encrypted Returns

**Wrong**:
```solidity
// ❌ View function cannot properly handle encrypted returns
function getBalance() external view returns (uint32) {
    // Cannot decrypt in view function!
    return FHE.decrypt(balance); // This doesn't exist!
}
```

**Correct**:
```solidity
// ✅ Return encrypted handle for client-side decryption
function getBalance() external view returns (euint32) {
    return balance;
}

// Client-side decryption
const encryptedBalance = await contract.getBalance();
const decrypted = await fhevm.decrypt(contractAddr, encryptedBalance);
```

**Why**: Decryption requires off-chain computation. View functions should return encrypted handles.

---

### ❌ Anti-Pattern 8: Performing Operations in View Functions

**Wrong**:
```solidity
function calculateTotal() external view returns (euint32) {
    // ❌ Creating new encrypted values in view function
    euint32 fee = FHE.asEuint32(100);
    euint32 total = FHE.add(balance, fee);
    return total; // This won't work properly
}
```

**Correct**:
```solidity
// ✅ Compute and store in state-changing function
function updateTotal() external {
    euint32 fee = FHE.asEuint32(100);
    total = FHE.add(balance, fee);

    FHE.allowThis(total);
    FHE.allow(total, msg.sender);
}

// ✅ View function just returns stored value
function getTotal() external view returns (euint32) {
    return total;
}
```

**Why**: FHE operations modify state and require proper permission setup. Use view functions only to return existing encrypted values.

---

## Permission Management Issues

### ❌ Anti-Pattern 9: Over-Permissive Access

**Wrong**:
```solidity
function deposit(inEuint32 calldata amount, bytes calldata proof) external {
    euint32 encrypted = FHE.asEuint32(amount, proof);
    balances[msg.sender] = encrypted;

    // ❌ Granting access to everyone!
    for (uint i = 0; i < allUsers.length; i++) {
        FHE.allow(balances[msg.sender], allUsers[i]);
    }
}
```

**Correct**:
```solidity
function deposit(inEuint32 calldata amount, bytes calldata proof) external {
    euint32 encrypted = FHE.asEuint32(amount, proof);
    balances[msg.sender] = encrypted;

    // ✅ Grant access only to contract and user
    FHE.allowThis(balances[msg.sender]);
    FHE.allow(balances[msg.sender], msg.sender);
}

// ✅ Explicit function for granting access
function grantAccessToBalance(address user) external {
    require(msg.sender == owner, "Not authorized");
    FHE.allow(balances[owner], user);
}
```

**Why**: Follow principle of least privilege. Only grant necessary permissions.

---

### ❌ Anti-Pattern 10: Not Revoking Permissions

**Wrong**:
```solidity
function completeLoan() external {
    require(isRepaid, "Not repaid");

    // ❌ Lender still has access to borrower's credit score
    // No way to revoke permissions
}
```

**Correct**:
```solidity
// Note: FHEVM doesn't support permission revocation
// ✅ Design pattern: Use temporary permissions
function getLoanApproval() external {
    // Grant temporary access for approval process
    FHE.allowTransient(creditScore, lender);

    // After approval, new encrypted values have no lender access
}

// ✅ Alternative: Create new encrypted value without old permissions
function resetCreditScore(inEuint8 calldata newScore, bytes calldata proof) external {
    euint8 encrypted = FHE.asEuint8(newScore, proof);
    creditScore = encrypted; // Old permissions don't transfer

    FHE.allowThis(creditScore);
    FHE.allow(creditScore, msg.sender);
}
```

**Why**: FHEVM permissions cannot be revoked. Design your system to use temporary permissions or create new encrypted values when access should change.

---

## Encryption Type Misuse

### ❌ Anti-Pattern 11: Using Wrong Encrypted Type Size

**Wrong**:
```solidity
// ❌ Using euint64 for small values (0-100)
euint64 private creditScore; // Wastes gas!

function updateScore(inEuint64 calldata score, bytes calldata proof) external {
    creditScore = FHE.asEuint64(score, proof);
}
```

**Correct**:
```solidity
// ✅ Use euint8 for small ranges (0-255)
euint8 private creditScore;

function updateScore(inEuint8 calldata score, bytes calldata proof) external {
    creditScore = FHE.asEuint8(score, proof);

    FHE.allowThis(creditScore);
    FHE.allow(creditScore, msg.sender);
}
```

**Why**: Use the smallest type that fits your data range. Larger types cost more gas.

**Type Recommendations**:
- `euint8` (0-255): Age, percentage, small counters
- `euint32` (0-4B): Balances, amounts, timestamps
- `euint64` (0-18T): Large financial values

---

### ❌ Anti-Pattern 12: Mixing Encrypted and Plaintext Incorrectly

**Wrong**:
```solidity
function badMath(euint32 encrypted, uint32 plain) external {
    // ❌ Cannot directly operate on encrypted and plaintext
    uint32 result = encrypted + plain; // Compile error!
}
```

**Correct**:
```solidity
function goodMath(euint32 encrypted, uint32 plain) external {
    // ✅ Convert plaintext to encrypted first
    euint32 encryptedPlain = FHE.asEuint32(plain);
    euint32 result = FHE.add(encrypted, encryptedPlain);

    FHE.allowThis(result);
}
```

**Why**: FHE operations require both operands to be encrypted. Convert plaintext values using `FHE.asEuintX()`.

---

## Handle Lifecycle Errors

### ❌ Anti-Pattern 13: Storing Handles Instead of Values

**Wrong**:
```solidity
// ❌ Storing handle (reference) instead of encrypted value
uint256 private balanceHandle;

function setBalance(inEuint32 calldata amount, bytes calldata proof) external {
    euint32 encrypted = FHE.asEuint32(amount, proof);
    balanceHandle = uint256(keccak256(abi.encode(encrypted))); // Wrong!
}
```

**Correct**:
```solidity
// ✅ Store the encrypted value directly
euint32 private balance;

function setBalance(inEuint32 calldata amount, bytes calldata proof) external {
    balance = FHE.asEuint32(amount, proof);

    FHE.allowThis(balance);
    FHE.allow(balance, msg.sender);
}
```

**Why**: Store encrypted types (`euintX`) directly, not their handles or hashes.

---

### ❌ Anti-Pattern 14: Returning Encrypted Values Without Permissions

**Wrong**:
```solidity
function getBalance() external view returns (euint32) {
    // ❌ Caller might not have permission to decrypt
    return balance;
}
```

**Correct**:
```solidity
// ✅ Document permission requirements
/// @notice Get encrypted balance
/// @dev Caller must have decrypt permission (granted during deposit)
/// @return Encrypted balance (requires permission to decrypt)
function getBalance() external view returns (euint32) {
    return balance;
}

// ✅ Or provide explicit access granting
function getBalanceWithAccess() external returns (euint32) {
    FHE.allow(balance, msg.sender);
    return balance;
}
```

**Why**: Document permission requirements clearly. Consider if access should be automatically granted.

---

## Gas Optimization Mistakes

### ❌ Anti-Pattern 15: Redundant Permission Grants

**Wrong**:
```solidity
function updateBalance() external {
    euint32 temp1 = FHE.add(balance, FHE.asEuint32(100));
    FHE.allowThis(temp1); // ❌ Unnecessary
    FHE.allow(temp1, msg.sender); // ❌ Unnecessary

    euint32 temp2 = FHE.mul(temp1, FHE.asEuint32(2));
    FHE.allowThis(temp2); // ❌ Unnecessary
    FHE.allow(temp2, msg.sender); // ❌ Unnecessary

    balance = temp2;
    FHE.allowThis(balance); // ✅ Only this needed
    FHE.allow(balance, msg.sender); // ✅ Only this needed
}
```

**Correct**:
```solidity
function updateBalance() external {
    // ✅ Perform all operations first
    euint32 temp1 = FHE.add(balance, FHE.asEuint32(100));
    euint32 temp2 = FHE.mul(temp1, FHE.asEuint32(2));

    // ✅ Grant permissions only on final result
    balance = temp2;
    FHE.allowThis(balance);
    FHE.allow(balance, msg.sender);
}
```

**Why**: Only grant permissions on final stored values, not intermediate calculations.

---

### ❌ Anti-Pattern 16: Using Encrypted Values for Public Data

**Wrong**:
```solidity
// ❌ Using encryption for publicly known values
euint32 public constant INTEREST_RATE = FHE.asEuint32(500); // 5%
euint32 public constant MAX_LOAN = FHE.asEuint32(1000000);
```

**Correct**:
```solidity
// ✅ Use plaintext for public constants
uint256 public constant INTEREST_RATE = 500; // 5%
uint256 public constant MAX_LOAN = 1000000;

// Only encrypt user data
euint32 private userLoanAmount;
```

**Why**: Encryption has gas costs. Only encrypt data that must be private.

---

## Security Vulnerabilities

### ❌ Anti-Pattern 17: Trusting User-Provided Plaintext

**Wrong**:
```solidity
function setBalance(uint32 amount) external {
    // ❌ User claims balance without proof
    balance = FHE.asEuint32(amount);
    FHE.allowThis(balance);
}
```

**Correct**:
```solidity
function setBalance(inEuint32 calldata amount, bytes calldata proof) external {
    // ✅ Verify with input proof
    balance = FHE.asEuint32(amount, proof);

    // ✅ Additional validation
    require(balanceIsValid(balance), "Invalid balance");

    FHE.allowThis(balance);
    FHE.allow(balance, msg.sender);
}
```

**Why**: Always require input proofs for user-submitted encrypted values.

---

### ❌ Anti-Pattern 18: Missing Input Validation

**Wrong**:
```solidity
function requestLoan(inEuint32 calldata amount, bytes calldata proof) external {
    // ❌ No validation on encrypted input
    loanAmount = FHE.asEuint32(amount, proof);
}
```

**Correct**:
```solidity
function requestLoan(
    inEuint32 calldata amount,
    bytes calldata proof,
    uint32 maxAmount // Plaintext upper bound for validation
) external {
    euint32 encrypted = FHE.asEuint32(amount, proof);

    // ✅ Validate against maximum (if possible)
    euint32 maxEncrypted = FHE.asEuint32(maxAmount);
    ebool isValid = FHE.lte(encrypted, maxEncrypted);
    require(FHE.decrypt(isValid), "Amount exceeds maximum");

    loanAmount = encrypted;
    FHE.allowThis(loanAmount);
    FHE.allow(loanAmount, msg.sender);
}
```

**Why**: Validate encrypted inputs where possible to prevent invalid states.

---

## Summary Checklist

Before deploying your FHEVM contract, verify:

### Access Control
- [ ] `FHE.allowThis()` called after every state update
- [ ] `FHE.allow()` grants minimal necessary permissions
- [ ] Permissions granted in correct order (operations first, then permissions)

### Input Handling
- [ ] All encrypted inputs require input proofs
- [ ] Signer matches transaction caller
- [ ] Fresh proofs for each submission

### View Functions
- [ ] View functions return encrypted handles, not decrypted values
- [ ] No FHE operations in view functions
- [ ] Permission requirements documented

### Type Usage
- [ ] Smallest appropriate type used (euint8 vs euint32 vs euint64)
- [ ] Plaintext-to-encrypted conversion using `FHE.asEuintX()`
- [ ] No encryption of public constants

### Gas Optimization
- [ ] Permissions granted only on final results
- [ ] No redundant permission grants
- [ ] Minimal encrypted storage

### Security
- [ ] Input validation where possible
- [ ] No trust in user-provided plaintext
- [ ] Proper error handling

---

## Additional Resources

- [FHEVM Best Practices](https://docs.zama.ai/fhevm/best-practices)
- [Common Errors Guide](https://docs.zama.ai/fhevm/errors)
- [Developer Guide](./DEVELOPER_GUIDE.md)

---

**Last Updated**: December 2025

**Remember**: When in doubt, refer to working examples in the `examples/` directory!
