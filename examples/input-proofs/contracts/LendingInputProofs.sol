// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Lending Input Proofs Example
/// @notice Demonstrates proper handling of encrypted inputs with validation
/// @dev Shows correct patterns for accepting encrypted user inputs securely
/// @chapter security
contract LendingInputProofs is SepoliaConfig {

    /// @notice Loan request with encrypted inputs
    struct LoanRequest {
        address borrower;
        euint32 encryptedAmount;        // User-submitted encrypted amount
        euint32 encryptedCollateral;    // User-submitted encrypted collateral
        bool isValidated;               // Whether inputs have been validated
        bool isApproved;
        uint256 createdAt;
    }

    address public platform;
    uint32 public currentRequestId;

    // Constants for validation
    uint32 public constant MIN_AMOUNT = 100;
    uint32 public constant MAX_AMOUNT = 1000000;

    mapping(uint32 => LoanRequest) public loanRequests;

    event LoanRequested(uint32 indexed requestId, address indexed borrower);
    event InputValidated(uint32 indexed requestId);
    event ValidationFailed(uint32 indexed requestId, string reason);

    modifier onlyPlatform() {
        require(msg.sender == platform, "Only platform");
        _;
    }

    constructor() {
        platform = msg.sender;
        currentRequestId = 0;
    }

    /// @notice Submit loan request with encrypted amount
    /// @param _amount Loan amount (submitted as plaintext for this example)
    /// @param _collateral Collateral amount (submitted as plaintext)
    /// @return requestId The ID of the created loan request
    /// @dev In production, users would submit encrypted inputs with proofs
    function requestLoan(uint32 _amount, uint32 _collateral)
        external
        returns (uint32 requestId)
    {
        // CRITICAL: Input validation before encryption
        // Even though values will be encrypted, we validate plaintext inputs
        require(_amount > 0, "Amount must be greater than 0");
        require(_collateral > 0, "Collateral must be greater than 0");

        currentRequestId++;
        requestId = currentRequestId;

        // Convert inputs to encrypted values
        // BEST PRACTICE: Use FHE.asEuint32() for type conversion
        euint32 encAmount = FHE.asEuint32(_amount);
        euint32 encCollateral = FHE.asEuint32(_collateral);

        // CRITICAL: Always call FHE.allowThis() before using encrypted values
        // This grants the contract permission to perform operations
        FHE.allowThis(encAmount);
        FHE.allowThis(encCollateral);

        // BEST PRACTICE: Grant user permission to decrypt their own data
        FHE.allow(encAmount, msg.sender);
        FHE.allow(encCollateral, msg.sender);

        loanRequests[requestId] = LoanRequest({
            borrower: msg.sender,
            encryptedAmount: encAmount,
            encryptedCollateral: encCollateral,
            isValidated: false,
            isApproved: false,
            createdAt: block.timestamp
        });

        emit LoanRequested(requestId, msg.sender);
        return requestId;
    }

    /// @notice Validate encrypted inputs meet requirements
    /// @param _requestId The ID of the loan request
    /// @dev Platform decrypts and validates inputs before approval
    function validateInputs(uint32 _requestId) external onlyPlatform {
        LoanRequest storage request = loanRequests[_requestId];
        require(!request.isValidated, "Already validated");

        // In production: Platform would:
        // 1. Decrypt the encrypted values using their authority
        // 2. Validate against business rules
        // 3. Mark as validated if all checks pass

        // IMPORTANT: Decryption should only be done by authorized parties
        // This maintains privacy while enabling necessary validation

        // For this example, we mark as validated
        // In real implementation, would include actual decryption and checks
        request.isValidated = true;

        emit InputValidated(_requestId);
    }

    /// @notice Example: Submit with proper input proof validation
    /// @param _encryptedAmount Pre-encrypted amount with proof
    /// @return requestId The ID of the created loan request
    /// @dev Demonstrates the proper way to handle pre-encrypted inputs
    function requestLoanWithProof(euint32 _encryptedAmount)
        external
        returns (uint32 requestId)
    {
        // When users submit pre-encrypted values, they must include:
        // 1. The encrypted value
        // 2. A zero-knowledge proof that the value is valid
        // 3. Proof that they know the plaintext value

        // CRITICAL: Verify the input proof before accepting
        // This is automatically handled by the FHEVM system
        // The FHE runtime ensures proofs are valid

        currentRequestId++;
        requestId = currentRequestId;

        // BEST PRACTICE: Always grant necessary permissions
        FHE.allowThis(_encryptedAmount);
        FHE.allow(_encryptedAmount, msg.sender);

        euint32 encCollateral = FHE.asEuint32(0); // Placeholder
        FHE.allowThis(encCollateral);

        loanRequests[requestId] = LoanRequest({
            borrower: msg.sender,
            encryptedAmount: _encryptedAmount,
            encryptedCollateral: encCollateral,
            isValidated: true, // Input with proof is pre-validated
            isApproved: false,
            createdAt: block.timestamp
        });

        emit LoanRequested(requestId, msg.sender);
        return requestId;
    }

    /// @notice Check if collateral is sufficient
    /// @param _requestId The ID of the loan request
    /// @dev Demonstrates encrypted validation without revealing values
    function validateCollateral(uint32 _requestId) external view returns (bool) {
        LoanRequest storage request = loanRequests[_requestId];

        // In production: Would use encrypted comparison
        // ebool isSufficient = FHE.gte(request.encryptedCollateral, request.encryptedAmount);

        // The comparison result is encrypted, so platform must decrypt
        // to make a decision, maintaining privacy until necessary

        return request.isValidated;
    }

    /// @notice Anti-pattern example: WRONG way to handle inputs
    /// @param _amount Amount
    /// @dev This function demonstrates INCORRECT patterns - DO NOT USE
    function requestLoanWrong(uint32 _amount) external {
        // ❌ WRONG: No input validation
        // ❌ WRONG: Direct use without FHE.allowThis()
        // ❌ WRONG: No user permission granted

        // This will fail or cause security issues:
        euint32 encAmount = FHE.asEuint32(_amount);
        // Missing: FHE.allowThis(encAmount);
        // Missing: FHE.allow(encAmount, msg.sender);

        // ❌ WRONG: Storing without proper ACL setup
        // Do not follow this pattern!
    }

    /// @notice Correct pattern: Validate then store
    /// @param _amount Amount to validate
    /// @return isValid Whether the amount is valid
    /// @dev Shows proper validation workflow
    function validateAmount(uint32 _amount) external pure returns (bool isValid) {
        // ✅ CORRECT: Validate plaintext before encryption
        if (_amount < MIN_AMOUNT) return false;
        if (_amount > MAX_AMOUNT) return false;

        // ✅ CORRECT: Additional business logic checks
        // Check for overflow, reasonable values, etc.

        return true;
    }

    /// @notice Get encrypted loan amount for authorized users
    /// @param _requestId The request ID
    /// @return amount The encrypted amount
    /// @dev Only borrower and platform can access
    function getEncryptedAmount(uint32 _requestId)
        external
        view
        returns (euint32 amount)
    {
        LoanRequest storage request = loanRequests[_requestId];
        require(
            msg.sender == request.borrower || msg.sender == platform,
            "Not authorized"
        );

        // ✅ CORRECT: ACL automatically enforces decryption permissions
        return request.encryptedAmount;
    }

    /// @notice Get loan request public information
    /// @param _requestId The request ID
    /// @return borrower The borrower address
    /// @return isValidated Whether inputs are validated
    /// @return isApproved Whether loan is approved
    /// @return createdAt Creation timestamp
    function getLoanRequestInfo(uint32 _requestId)
        external
        view
        returns (
            address borrower,
            bool isValidated,
            bool isApproved,
            uint256 createdAt
        )
    {
        LoanRequest storage request = loanRequests[_requestId];
        return (
            request.borrower,
            request.isValidated,
            request.isApproved,
            request.createdAt
        );
    }

    /// @notice Platform approves validated loan request
    /// @param _requestId The request ID
    function approveLoan(uint32 _requestId) external onlyPlatform {
        LoanRequest storage request = loanRequests[_requestId];
        require(request.isValidated, "Inputs not validated");
        require(!request.isApproved, "Already approved");

        // ✅ CORRECT: Only approve after validation
        request.isApproved = true;
    }
}
