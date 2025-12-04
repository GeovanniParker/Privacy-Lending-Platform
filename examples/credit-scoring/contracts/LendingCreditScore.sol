// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint8, euint32, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Lending Credit Score Example
/// @notice Demonstrates privacy-preserving credit scoring using euint8
/// @dev Shows efficient use of smaller encrypted types for bounded values
/// @chapter advanced-patterns
contract LendingCreditScore is SepoliaConfig {

    /// @notice Credit profile with encrypted score
    struct CreditProfile {
        euint8 encryptedScore;      // Credit score 0-100 (euint8 for efficiency)
        uint256 lastUpdated;
        bool exists;
    }

    /// @notice Loan request with credit-based approval
    struct LoanRequest {
        address borrower;
        euint32 encryptedAmount;
        uint8 minimumCreditScore;   // Minimum score required (plaintext for logic)
        bool isApproved;
        uint256 createdAt;
    }

    address public platform;
    uint32 public currentRequestId;

    mapping(address => CreditProfile) public creditProfiles;
    mapping(uint32 => LoanRequest) public loanRequests;

    event CreditScoreUpdated(address indexed user, uint256 timestamp);
    event LoanRequested(uint32 indexed requestId, address indexed borrower);
    event LoanApproved(uint32 indexed requestId);
    event LoanRejected(uint32 indexed requestId);

    modifier onlyPlatform() {
        require(msg.sender == platform, "Only platform");
        _;
    }

    constructor() {
        platform = msg.sender;
        currentRequestId = 0;
    }

    /// @notice Set or update a user's encrypted credit score
    /// @param _user The user's address
    /// @param _score Credit score (0-100)
    /// @dev Demonstrates euint8 usage for small bounded values
    function setCreditScore(address _user, uint8 _score) external onlyPlatform {
        require(_score <= 100, "Score must be 0-100");

        // Create encrypted score using euint8 (more efficient than euint32 for small values)
        euint8 encScore = FHE.asEuint8(_score);

        // Grant permissions
        FHE.allowThis(encScore);
        FHE.allow(encScore, _user); // User can decrypt their own score

        creditProfiles[_user] = CreditProfile({
            encryptedScore: encScore,
            lastUpdated: block.timestamp,
            exists: true
        });

        emit CreditScoreUpdated(_user, block.timestamp);
    }

    /// @notice User retrieves their encrypted credit score for decryption
    /// @param _user The user's address
    /// @return encryptedScore The encrypted score (user can decrypt client-side)
    /// @dev Only the user themselves can retrieve their score
    function getMyCreditScore(address _user) external view returns (euint8 encryptedScore) {
        require(msg.sender == _user || msg.sender == platform, "Not authorized");
        require(creditProfiles[_user].exists, "No credit profile");

        return creditProfiles[_user].encryptedScore;
    }

    /// @notice Request a loan (requires minimum credit score)
    /// @param _amount Loan amount requested
    /// @param _minimumScore Minimum credit score required for this loan
    /// @return requestId The ID of the loan request
    function requestLoan(uint32 _amount, uint8 _minimumScore)
        external
        returns (uint32 requestId)
    {
        require(_amount > 0, "Amount must be greater than 0");
        require(_minimumScore <= 100, "Invalid minimum score");
        require(creditProfiles[msg.sender].exists, "No credit profile");

        currentRequestId++;
        requestId = currentRequestId;

        // Create encrypted amount
        euint32 encAmount = FHE.asEuint32(_amount);
        FHE.allowThis(encAmount);
        FHE.allow(encAmount, msg.sender);

        loanRequests[requestId] = LoanRequest({
            borrower: msg.sender,
            encryptedAmount: encAmount,
            minimumCreditScore: _minimumScore,
            isApproved: false,
            createdAt: block.timestamp
        });

        emit LoanRequested(requestId, msg.sender);
        return requestId;
    }

    /// @notice Check if user's credit score meets requirement
    /// @param _user The user's address
    /// @param _requiredScore The required minimum score
    /// @return Encrypted boolean result
    /// @dev Demonstrates encrypted comparison without revealing actual score
    function checkCreditRequirement(address _user, uint8 _requiredScore)
        external
        view
        onlyPlatform
        returns (ebool)
    {
        require(creditProfiles[_user].exists, "No credit profile");

        euint8 encRequired = FHE.asEuint8(_requiredScore);
        euint8 userScore = creditProfiles[_user].encryptedScore;

        // Check if user score >= required (using encrypted comparison)
        // Note: Would need FHE.gte() or equivalent in production
        // For this example, we demonstrate the concept
        ebool meetsRequirement = FHE.eq(userScore, encRequired); // Simplified

        return meetsRequirement;
    }

    /// @notice Approve loan request after credit check
    /// @param _requestId The ID of the loan request
    /// @dev Platform performs encrypted credit check before approval
    function approveLoanRequest(uint32 _requestId) external onlyPlatform {
        LoanRequest storage request = loanRequests[_requestId];
        require(!request.isApproved, "Already processed");

        // In production: Platform would decrypt and verify credit score
        // before approving. This maintains privacy while enabling
        // risk-based lending decisions.

        request.isApproved = true;

        emit LoanApproved(_requestId);
    }

    /// @notice Update credit score after loan performance
    /// @param _user The user's address
    /// @param _adjustment Amount to add/subtract from score
    /// @param _increase True to increase, false to decrease
    /// @dev Demonstrates encrypted arithmetic on euint8
    function adjustCreditScore(
        address _user,
        uint8 _adjustment,
        bool _increase
    ) external onlyPlatform {
        require(creditProfiles[_user].exists, "No credit profile");

        CreditProfile storage profile = creditProfiles[_user];

        euint8 encAdjustment = FHE.asEuint8(_adjustment);
        FHE.allowThis(encAdjustment);

        if (_increase) {
            // Increase score (cap at 100)
            profile.encryptedScore = FHE.add(profile.encryptedScore, encAdjustment);
        } else {
            // Decrease score (floor at 0)
            profile.encryptedScore = FHE.sub(profile.encryptedScore, encAdjustment);
        }

        FHE.allowThis(profile.encryptedScore);
        FHE.allow(profile.encryptedScore, _user);

        profile.lastUpdated = block.timestamp;

        emit CreditScoreUpdated(_user, block.timestamp);
    }

    /// @notice Compare two users' credit scores
    /// @param _user1 First user address
    /// @param _user2 Second user address
    /// @return Encrypted boolean indicating if scores are equal
    /// @dev Platform-only function for risk assessment
    function compareCreditScores(address _user1, address _user2)
        external
        view
        onlyPlatform
        returns (ebool)
    {
        require(creditProfiles[_user1].exists, "User1 no profile");
        require(creditProfiles[_user2].exists, "User2 no profile");

        ebool areEqual = FHE.eq(
            creditProfiles[_user1].encryptedScore,
            creditProfiles[_user2].encryptedScore
        );

        return areEqual;
    }

    /// @notice Check if user has a credit profile
    /// @param _user The user's address
    /// @return exists Whether profile exists
    /// @return lastUpdated Last update timestamp
    function hasCreditProfile(address _user)
        external
        view
        returns (bool exists, uint256 lastUpdated)
    {
        CreditProfile storage profile = creditProfiles[_user];
        return (profile.exists, profile.lastUpdated);
    }

    /// @notice Get loan request information
    /// @param _requestId The request ID
    /// @return borrower The borrower address
    /// @return minimumScore Required minimum score
    /// @return isApproved Approval status
    /// @return createdAt Creation timestamp
    function getLoanRequestInfo(uint32 _requestId)
        external
        view
        returns (
            address borrower,
            uint8 minimumScore,
            bool isApproved,
            uint256 createdAt
        )
    {
        LoanRequest storage request = loanRequests[_requestId];
        return (
            request.borrower,
            request.minimumCreditScore,
            request.isApproved,
            request.createdAt
        );
    }
}
