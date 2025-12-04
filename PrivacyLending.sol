pragma solidity ^0.8.24;

import { FHE, euint8, euint32, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Privacy Lending - Anonymous Consumer Loan Platform
/// @notice Implements a privacy-preserving peer-to-peer lending system using FHE
/// @dev Uses Zama's fhEVM for encrypted loan amounts and credit scores
contract PrivacyLending is SepoliaConfig {

    // Encrypted loan data structure
    struct Loan {
        address borrower;
        euint32 encryptedAmount;          // Encrypted loan amount
        uint256 interestRate;             // Interest rate in basis points (e.g., 500 = 5%)
        uint256 durationMonths;           // Loan duration in months
        bool isApproved;                  // Platform approval status
        bool isFunded;                    // Lender funding status
        bool isRepaid;                    // Full repayment status
        uint256 createdAt;                // Timestamp of loan request
        address lender;                   // Address of the lender
        euint32 encryptedTotalRepayment;  // Encrypted total amount to repay
        euint32 encryptedRemainingBalance; // Encrypted remaining balance
    }

    // Credit score for privacy-preserving risk assessment
    struct CreditProfile {
        euint8 encryptedCreditScore;      // Encrypted credit score (0-100)
        uint256 lastUpdated;              // Last update timestamp
        bool exists;                      // Profile existence flag
    }

    // State variables
    address public platform;              // Platform administrator
    uint32 public currentLoanId;          // Counter for loan IDs

    // Mappings
    mapping(uint32 => Loan) public loans;
    mapping(address => CreditProfile) public creditProfiles;
    mapping(address => uint256) public lenderDeposits;
    mapping(address => uint32[]) public borrowerLoans;

    // Constants
    uint256 public constant MIN_INTEREST_RATE = 300;    // 3% APR
    uint256 public constant MAX_INTEREST_RATE = 3000;   // 30% APR
    uint256 public constant PLATFORM_FEE = 50;          // 0.5% platform fee

    // Events
    event LoanRequested(uint32 indexed loanId, address indexed borrower, uint256 timestamp);
    event LoanApproved(uint32 indexed loanId, uint256 interestRate, uint256 duration);
    event LoanFunded(uint32 indexed loanId, address indexed lender, uint256 timestamp);
    event PaymentMade(uint32 indexed loanId, address indexed borrower, uint256 timestamp);
    event LoanRepaid(uint32 indexed loanId, address indexed borrower, uint256 timestamp);
    event LenderDeposited(address indexed lender, uint256 amount);
    event LenderWithdrew(address indexed lender, uint256 amount);
    event CreditScoreUpdated(address indexed user, uint256 timestamp);

    // Modifiers
    modifier onlyPlatform() {
        require(msg.sender == platform, "Only platform can call this");
        _;
    }

    modifier onlyBorrower(uint32 _loanId) {
        require(loans[_loanId].borrower == msg.sender, "Only borrower can call this");
        _;
    }

    modifier loanExists(uint32 _loanId) {
        require(loans[_loanId].borrower != address(0), "Loan does not exist");
        _;
    }

    constructor() {
        platform = msg.sender;
        currentLoanId = 0;
    }

    /// @notice Submit an encrypted loan request
    /// @param _amount Encrypted loan amount requested
    /// @param _durationMonths Duration of the loan in months
    function requestLoan(uint32 _amount, uint256 _durationMonths) external {
        require(_durationMonths > 0 && _durationMonths <= 60, "Invalid duration");
        require(_amount > 0, "Amount must be greater than 0");

        currentLoanId++;

        // Create encrypted amount
        euint32 encAmount = FHE.asEuint32(_amount);

        loans[currentLoanId] = Loan({
            borrower: msg.sender,
            encryptedAmount: encAmount,
            interestRate: 0,
            durationMonths: _durationMonths,
            isApproved: false,
            isFunded: false,
            isRepaid: false,
            createdAt: block.timestamp,
            lender: address(0),
            encryptedTotalRepayment: FHE.asEuint32(0),
            encryptedRemainingBalance: FHE.asEuint32(0)
        });

        borrowerLoans[msg.sender].push(currentLoanId);

        // Grant ACL permissions
        FHE.allowThis(encAmount);
        FHE.allow(encAmount, msg.sender);

        emit LoanRequested(currentLoanId, msg.sender, block.timestamp);
    }

    /// @notice Platform approves a loan with interest rate
    /// @param _loanId The ID of the loan to approve
    /// @param _interestRate Interest rate in basis points
    function approveLoan(uint32 _loanId, uint256 _interestRate) external onlyPlatform loanExists(_loanId) {
        Loan storage loan = loans[_loanId];
        require(!loan.isApproved, "Loan already approved");
        require(_interestRate >= MIN_INTEREST_RATE && _interestRate <= MAX_INTEREST_RATE, "Invalid interest rate");

        loan.isApproved = true;
        loan.interestRate = _interestRate;

        // Calculate encrypted total repayment amount
        // Total = Principal * (1 + InterestRate * Duration / 12)
        // We calculate the multiplier as: (10000 + InterestRate * Duration / 12) / 10000
        // To avoid division on encrypted data, we pre-calculate the multiplier
        uint32 interestMultiplier = uint32(10000 + (_interestRate * loan.durationMonths / 12));
        // Multiply encrypted amount by the multiplier, then we'll handle scaling off-chain
        euint32 scaledRepayment = FHE.mul(loan.encryptedAmount, FHE.asEuint32(interestMultiplier));

        // Store the scaled value (needs to be divided by 10000 when decrypted)
        loan.encryptedTotalRepayment = scaledRepayment;
        loan.encryptedRemainingBalance = scaledRepayment;

        // Grant ACL permissions
        FHE.allowThis(scaledRepayment);
        FHE.allow(scaledRepayment, loan.borrower);

        emit LoanApproved(_loanId, _interestRate, loan.durationMonths);
    }

    /// @notice Platform sets the actual loan amount (after risk assessment)
    /// @param _loanId The ID of the loan
    /// @param _amount The approved loan amount
    function setLoanAmount(uint32 _loanId, uint32 _amount) external onlyPlatform loanExists(_loanId) {
        Loan storage loan = loans[_loanId];
        require(loan.isApproved, "Loan not approved");
        require(!loan.isFunded, "Loan already funded");

        euint32 newAmount = FHE.asEuint32(_amount);
        loan.encryptedAmount = newAmount;

        // Recalculate total repayment (scaled by 10000)
        uint32 interestMultiplier = uint32(10000 + (loan.interestRate * loan.durationMonths / 12));
        euint32 scaledRepayment = FHE.mul(loan.encryptedAmount, FHE.asEuint32(interestMultiplier));

        loan.encryptedTotalRepayment = scaledRepayment;
        loan.encryptedRemainingBalance = scaledRepayment;

        // Grant ACL permissions
        FHE.allowThis(newAmount);
        FHE.allow(newAmount, loan.borrower);
        FHE.allowThis(scaledRepayment);
        FHE.allow(scaledRepayment, loan.borrower);
    }

    /// @notice Lender deposits funds into the platform
    function depositFunds() external payable {
        require(msg.value > 0, "Must deposit some amount");
        lenderDeposits[msg.sender] += msg.value;
        emit LenderDeposited(msg.sender, msg.value);
    }

    /// @notice Lender funds an approved loan
    /// @param _loanId The ID of the loan to fund
    /// @param _amount The amount to fund (for verification)
    function fundLoan(uint32 _loanId, uint32 _amount) external loanExists(_loanId) {
        Loan storage loan = loans[_loanId];
        require(loan.isApproved, "Loan not approved");
        require(!loan.isFunded, "Loan already funded");
        require(loan.borrower != msg.sender, "Cannot fund your own loan");

        // Verify lender has sufficient deposits
        uint256 amountInWei = uint256(_amount) * 1 gwei;
        require(lenderDeposits[msg.sender] >= amountInWei, "Insufficient deposit balance");

        // Transfer funds to borrower
        lenderDeposits[msg.sender] -= amountInWei;
        loan.lender = msg.sender;
        loan.isFunded = true;

        payable(loan.borrower).transfer(amountInWei);

        emit LoanFunded(_loanId, msg.sender, block.timestamp);
    }

    /// @notice Borrower makes a payment on the loan
    /// @param _loanId The ID of the loan
    function makePayment(uint32 _loanId) external payable onlyBorrower(_loanId) loanExists(_loanId) {
        Loan storage loan = loans[_loanId];
        require(loan.isFunded, "Loan not funded");
        require(!loan.isRepaid, "Loan already repaid");
        require(msg.value > 0, "Payment must be greater than 0");

        // Convert payment to encrypted value
        uint32 paymentAmount = uint32(msg.value / 1 gwei);
        euint32 encPayment = FHE.asEuint32(paymentAmount);

        // Subtract payment from remaining balance
        loan.encryptedRemainingBalance = FHE.sub(loan.encryptedRemainingBalance, encPayment);

        // Check if loan is fully repaid (in real implementation, this would be done securely)
        // For demo purposes, we'll use a threshold check
        ebool isZero = FHE.eq(loan.encryptedRemainingBalance, FHE.asEuint32(0));

        // Transfer payment to lender
        payable(loan.lender).transfer(msg.value);

        emit PaymentMade(_loanId, msg.sender, block.timestamp);

        // Note: In production, you'd need a secure way to check if remaining balance is zero
        // This could involve decryption by authorized parties or threshold decryption
    }

    /// @notice Mark loan as fully repaid (only platform after verification)
    /// @param _loanId The ID of the loan
    function markLoanRepaid(uint32 _loanId) external onlyPlatform loanExists(_loanId) {
        Loan storage loan = loans[_loanId];
        require(loan.isFunded, "Loan not funded");
        require(!loan.isRepaid, "Loan already repaid");

        loan.isRepaid = true;

        emit LoanRepaid(_loanId, loan.borrower, block.timestamp);
    }

    /// @notice Update encrypted credit score for a user
    /// @param _user The user's address
    /// @param _score Credit score (0-100)
    function updateCreditScore(address _user, uint8 _score) external onlyPlatform {
        require(_score <= 100, "Invalid credit score");

        euint8 encScore = FHE.asEuint8(_score);

        creditProfiles[_user] = CreditProfile({
            encryptedCreditScore: encScore,
            lastUpdated: block.timestamp,
            exists: true
        });

        // Grant ACL permissions
        FHE.allowThis(encScore);
        FHE.allow(encScore, _user);

        emit CreditScoreUpdated(_user, block.timestamp);
    }

    /// @notice Lender withdraws deposited funds
    /// @param _amount The amount to withdraw
    function withdrawFunds(uint256 _amount) external {
        require(lenderDeposits[msg.sender] >= _amount, "Insufficient balance");

        lenderDeposits[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit LenderWithdrew(msg.sender, _amount);
    }

    /// @notice Get loan information (public data only)
    /// @param _loanId The ID of the loan
    /// @return borrower The borrower's address
    /// @return isApproved Approval status
    /// @return isFunded Funding status
    /// @return isRepaid Repayment status
    function getLoanInfo(uint32 _loanId) external view loanExists(_loanId)
        returns (address borrower, bool isApproved, bool isFunded, bool isRepaid) {
        Loan storage loan = loans[_loanId];
        return (loan.borrower, loan.isApproved, loan.isFunded, loan.isRepaid);
    }

    /// @notice Get all loan IDs for a borrower
    /// @param _borrower The borrower's address
    /// @return Array of loan IDs
    function getBorrowerLoans(address _borrower) external view returns (uint32[] memory) {
        return borrowerLoans[_borrower];
    }

    /// @notice Get encrypted loan amount (only borrower or platform)
    /// @param _loanId The ID of the loan
    /// @return Encrypted amount
    function getEncryptedLoanAmount(uint32 _loanId) external view loanExists(_loanId) returns (euint32) {
        Loan storage loan = loans[_loanId];
        require(msg.sender == loan.borrower || msg.sender == platform, "Not authorized");
        return loan.encryptedAmount;
    }

    /// @notice Get encrypted remaining balance (only borrower, lender, or platform)
    /// @param _loanId The ID of the loan
    /// @return Encrypted remaining balance
    function getEncryptedRemainingBalance(uint32 _loanId) external view loanExists(_loanId) returns (euint32) {
        Loan storage loan = loans[_loanId];
        require(
            msg.sender == loan.borrower ||
            msg.sender == loan.lender ||
            msg.sender == platform,
            "Not authorized"
        );
        return loan.encryptedRemainingBalance;
    }

    /// @notice Transfer platform ownership
    /// @param _newPlatform The new platform administrator
    function transferPlatform(address _newPlatform) external onlyPlatform {
        require(_newPlatform != address(0), "Invalid address");
        platform = _newPlatform;
    }

    /// @notice Emergency withdraw (only platform)
    function emergencyWithdraw() external onlyPlatform {
        payable(platform).transfer(address(this).balance);
    }

    receive() external payable {}
}
