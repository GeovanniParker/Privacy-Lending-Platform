// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Lending Comparison Operations Example
/// @notice Demonstrates FHE comparison operations for loan status checks
/// @dev Shows FHE.eq() and ebool usage for encrypted comparisons
/// @chapter comparison
contract LendingComparison is SepoliaConfig {

    /// @notice Loan with encrypted balance tracking
    struct Loan {
        address borrower;
        euint32 encryptedTotalDue;     // Total amount owed
        euint32 encryptedBalance;      // Current balance
        bool isFullyPaid;              // Repayment status
        uint256 createdAt;
    }

    address public platform;
    uint32 public currentLoanId;

    mapping(uint32 => Loan) public loans;

    event LoanCreated(uint32 indexed loanId, address indexed borrower);
    event PaymentReceived(uint32 indexed loanId, uint32 paymentAmount);
    event LoanFullyRepaid(uint32 indexed loanId);

    constructor() {
        platform = msg.sender;
        currentLoanId = 0;
    }

    /// @notice Create a loan with encrypted total amount due
    /// @param _totalDue Total amount the borrower must repay
    /// @return loanId The ID of the created loan
    function createLoan(uint32 _totalDue) external returns (uint32 loanId) {
        require(_totalDue > 0, "Total due must be greater than 0");

        currentLoanId++;
        loanId = currentLoanId;

        // Create encrypted total due
        euint32 encTotal = FHE.asEuint32(_totalDue);
        FHE.allowThis(encTotal);
        FHE.allow(encTotal, msg.sender);

        // Balance starts equal to total (nothing paid yet)
        euint32 encBalance = encTotal;

        loans[loanId] = Loan({
            borrower: msg.sender,
            encryptedTotalDue: encTotal,
            encryptedBalance: encBalance,
            isFullyPaid: false,
            createdAt: block.timestamp
        });

        emit LoanCreated(loanId, msg.sender);
        return loanId;
    }

    /// @notice Make a payment and check if loan is fully repaid
    /// @param _loanId The ID of the loan
    /// @param _paymentAmount The payment amount
    /// @dev Demonstrates FHE.eq() for checking if balance equals zero
    function makePayment(uint32 _loanId, uint32 _paymentAmount) external {
        Loan storage loan = loans[_loanId];
        require(loan.borrower == msg.sender, "Not the borrower");
        require(!loan.isFullyPaid, "Loan already fully paid");
        require(_paymentAmount > 0, "Payment must be greater than 0");

        // Create encrypted payment
        euint32 encPayment = FHE.asEuint32(_paymentAmount);
        FHE.allowThis(encPayment);

        // Subtract payment from balance
        loan.encryptedBalance = FHE.sub(loan.encryptedBalance, encPayment);
        FHE.allowThis(loan.encryptedBalance);
        FHE.allow(loan.encryptedBalance, msg.sender);

        emit PaymentReceived(_loanId, _paymentAmount);

        // FHE.eq() - Check if balance equals zero (fully repaid)
        // Returns an encrypted boolean (ebool)
        euint32 zero = FHE.asEuint32(0);
        ebool isZero = FHE.eq(loan.encryptedBalance, zero);

        // Note: In production, you would need a secure way to decrypt this boolean
        // This could involve:
        // 1. Platform decryption authority
        // 2. Threshold decryption
        // 3. Public decryption with proper ACL

        // For this example, we demonstrate the comparison operation
        // The actual decryption would happen through proper channels
    }

    /// @notice Platform confirms loan is fully repaid after verification
    /// @param _loanId The ID of the loan
    /// @dev In production, platform would decrypt and verify before calling this
    function markAsFullyPaid(uint32 _loanId) external {
        require(msg.sender == platform, "Only platform");

        Loan storage loan = loans[_loanId];
        require(!loan.isFullyPaid, "Already marked as paid");

        // In production: Platform would have decrypted the balance,
        // verified it equals zero, and then calls this function

        loan.isFullyPaid = true;

        emit LoanFullyRepaid(_loanId);
    }

    /// @notice Check if payment amount is sufficient to cover balance
    /// @param _loanId The ID of the loan
    /// @param _amount Amount to check
    /// @return Encrypted boolean result
    /// @dev Demonstrates encrypted comparison without revealing amounts
    function isAmountSufficient(uint32 _loanId, uint32 _amount)
        external
        view
        returns (ebool)
    {
        Loan storage loan = loans[_loanId];
        require(msg.sender == loan.borrower || msg.sender == platform, "Not authorized");

        euint32 encAmount = FHE.asEuint32(_amount);

        // FHE.eq() - Check if amount equals balance
        ebool isExact = FHE.eq(encAmount, loan.encryptedBalance);

        // Could also use:
        // FHE.lt() - Check if balance < amount (overpayment)
        // FHE.gt() - Check if balance > amount (underpayment)

        return isExact;
    }

    /// @notice Compare two loan balances
    /// @param _loanId1 First loan ID
    /// @param _loanId2 Second loan ID
    /// @return Encrypted boolean indicating if balances are equal
    /// @dev Shows comparison between two encrypted values
    function compareLoanBalances(uint32 _loanId1, uint32 _loanId2)
        external
        view
        returns (ebool)
    {
        require(msg.sender == platform, "Only platform");

        Loan storage loan1 = loans[_loanId1];
        Loan storage loan2 = loans[_loanId2];

        // FHE.eq() - Compare two encrypted balances
        ebool areEqual = FHE.eq(loan1.encryptedBalance, loan2.encryptedBalance);

        return areEqual;
    }

    /// @notice Get encrypted balance
    /// @param _loanId The ID of the loan
    /// @return The encrypted balance
    function getEncryptedBalance(uint32 _loanId) external view returns (euint32) {
        Loan storage loan = loans[_loanId];
        require(
            msg.sender == loan.borrower || msg.sender == platform,
            "Not authorized"
        );

        return loan.encryptedBalance;
    }

    /// @notice Get loan public information
    /// @param _loanId The ID of the loan
    /// @return borrower The borrower address
    /// @return isFullyPaid Repayment status
    /// @return createdAt Creation timestamp
    function getLoanInfo(uint32 _loanId)
        external
        view
        returns (address borrower, bool isFullyPaid, uint256 createdAt)
    {
        Loan storage loan = loans[_loanId];
        return (loan.borrower, loan.isFullyPaid, loan.createdAt);
    }
}
