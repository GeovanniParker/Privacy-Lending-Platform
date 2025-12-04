// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Lending Arithmetic Operations Example
/// @notice Demonstrates FHE arithmetic operations for loan calculations
/// @dev Shows FHE.add(), FHE.sub(), FHE.mul() on encrypted values
/// @chapter arithmetic
contract LendingArithmetic is SepoliaConfig {

    /// @notice Loan with encrypted amounts and calculations
    struct Loan {
        address borrower;
        euint32 encryptedPrincipal;       // Original loan amount
        euint32 encryptedInterest;        // Calculated interest amount
        euint32 encryptedTotal;           // Total repayment = principal + interest
        euint32 encryptedPaid;            // Amount paid so far
        euint32 encryptedRemaining;       // Remaining balance
        uint256 interestRate;             // Interest rate in basis points
        bool isActive;
    }

    address public platform;
    uint32 public currentLoanId;

    mapping(uint32 => Loan) public loans;

    event LoanCreated(uint32 indexed loanId, address indexed borrower);
    event InterestCalculated(uint32 indexed loanId, uint256 interestRate);
    event PaymentMade(uint32 indexed loanId, address indexed borrower);

    constructor() {
        platform = msg.sender;
        currentLoanId = 0;
    }

    /// @notice Create a loan with encrypted principal amount
    /// @param _principal The loan principal amount
    /// @param _interestRate Interest rate in basis points (e.g., 500 = 5%)
    /// @return loanId The ID of the created loan
    function createLoan(uint32 _principal, uint256 _interestRate)
        external
        returns (uint32 loanId)
    {
        require(_principal > 0, "Principal must be greater than 0");
        require(_interestRate <= 3000, "Interest rate too high"); // Max 30%

        currentLoanId++;
        loanId = currentLoanId;

        // Create encrypted principal
        euint32 encPrincipal = FHE.asEuint32(_principal);
        FHE.allowThis(encPrincipal);
        FHE.allow(encPrincipal, msg.sender);

        // Calculate encrypted interest: interest = principal * rate / 10000
        // FHE.mul() performs multiplication on encrypted values
        uint32 rateMultiplier = uint32(_interestRate);
        euint32 scaledAmount = FHE.mul(encPrincipal, FHE.asEuint32(rateMultiplier));
        FHE.allowThis(scaledAmount);

        // For this example, we store the scaled value
        // In production, division would be handled off-chain after decryption
        euint32 encInterest = scaledAmount;
        FHE.allow(encInterest, msg.sender);

        // FHE.add() performs addition on encrypted values
        // Calculate total = principal + interest
        euint32 encTotal = FHE.add(encPrincipal, encInterest);
        FHE.allowThis(encTotal);
        FHE.allow(encTotal, msg.sender);

        // Initialize paid amount to 0
        euint32 encPaid = FHE.asEuint32(0);
        FHE.allowThis(encPaid);

        // Remaining = total (initially)
        euint32 encRemaining = encTotal;
        FHE.allow(encRemaining, msg.sender);

        loans[loanId] = Loan({
            borrower: msg.sender,
            encryptedPrincipal: encPrincipal,
            encryptedInterest: encInterest,
            encryptedTotal: encTotal,
            encryptedPaid: encPaid,
            encryptedRemaining: encRemaining,
            interestRate: _interestRate,
            isActive: true
        });

        emit LoanCreated(loanId, msg.sender);
        emit InterestCalculated(loanId, _interestRate);

        return loanId;
    }

    /// @notice Make a payment on the loan
    /// @param _loanId The ID of the loan
    /// @param _paymentAmount The payment amount
    /// @dev Demonstrates FHE.add() and FHE.sub() for updating balances
    function makePayment(uint32 _loanId, uint32 _paymentAmount) external {
        Loan storage loan = loans[_loanId];
        require(loan.borrower == msg.sender, "Not the borrower");
        require(loan.isActive, "Loan not active");
        require(_paymentAmount > 0, "Payment must be greater than 0");

        // Create encrypted payment amount
        euint32 encPayment = FHE.asEuint32(_paymentAmount);
        FHE.allowThis(encPayment);

        // FHE.add() - Add payment to total paid
        // paid = paid + payment
        loan.encryptedPaid = FHE.add(loan.encryptedPaid, encPayment);
        FHE.allowThis(loan.encryptedPaid);
        FHE.allow(loan.encryptedPaid, msg.sender);

        // FHE.sub() - Subtract payment from remaining balance
        // remaining = remaining - payment
        loan.encryptedRemaining = FHE.sub(loan.encryptedRemaining, encPayment);
        FHE.allowThis(loan.encryptedRemaining);
        FHE.allow(loan.encryptedRemaining, msg.sender);

        emit PaymentMade(_loanId, msg.sender);
    }

    /// @notice Update interest rate and recalculate loan amounts
    /// @param _loanId The ID of the loan
    /// @param _newRate New interest rate in basis points
    /// @dev Demonstrates complex encrypted arithmetic workflow
    function updateInterestRate(uint32 _loanId, uint256 _newRate) external {
        require(msg.sender == platform, "Only platform");

        Loan storage loan = loans[_loanId];
        require(loan.isActive, "Loan not active");

        // Recalculate interest with new rate
        // FHE.mul() for multiplication
        uint32 rateMultiplier = uint32(_newRate);
        euint32 newScaledAmount = FHE.mul(
            loan.encryptedPrincipal,
            FHE.asEuint32(rateMultiplier)
        );
        FHE.allowThis(newScaledAmount);

        loan.encryptedInterest = newScaledAmount;
        FHE.allow(loan.encryptedInterest, loan.borrower);

        // Recalculate total: FHE.add()
        loan.encryptedTotal = FHE.add(loan.encryptedPrincipal, loan.encryptedInterest);
        FHE.allowThis(loan.encryptedTotal);
        FHE.allow(loan.encryptedTotal, loan.borrower);

        // Recalculate remaining: FHE.sub()
        loan.encryptedRemaining = FHE.sub(loan.encryptedTotal, loan.encryptedPaid);
        FHE.allowThis(loan.encryptedRemaining);
        FHE.allow(loan.encryptedRemaining, loan.borrower);

        loan.interestRate = _newRate;

        emit InterestCalculated(_loanId, _newRate);
    }

    /// @notice Get encrypted loan amounts
    /// @param _loanId The ID of the loan
    /// @return principal Encrypted principal
    /// @return interest Encrypted interest
    /// @return total Encrypted total
    /// @return paid Encrypted amount paid
    /// @return remaining Encrypted remaining balance
    function getEncryptedAmounts(uint32 _loanId)
        external
        view
        returns (
            euint32 principal,
            euint32 interest,
            euint32 total,
            euint32 paid,
            euint32 remaining
        )
    {
        Loan storage loan = loans[_loanId];
        require(
            msg.sender == loan.borrower || msg.sender == platform,
            "Not authorized"
        );

        return (
            loan.encryptedPrincipal,
            loan.encryptedInterest,
            loan.encryptedTotal,
            loan.encryptedPaid,
            loan.encryptedRemaining
        );
    }

    /// @notice Get loan public information
    /// @param _loanId The ID of the loan
    /// @return borrower The borrower address
    /// @return interestRate The interest rate
    /// @return isActive Whether loan is active
    function getLoanInfo(uint32 _loanId)
        external
        view
        returns (address borrower, uint256 interestRate, bool isActive)
    {
        Loan storage loan = loans[_loanId];
        return (loan.borrower, loan.interestRate, loan.isActive);
    }
}
