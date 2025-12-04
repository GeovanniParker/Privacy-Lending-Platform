// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Lending User Decryption Example
/// @notice Demonstrates user-specific decryption patterns for encrypted loan data
/// @dev Shows how authorized users can decrypt their own encrypted information
/// @chapter decryption
contract LendingUserDecryption is SepoliaConfig {

    /// @notice Loan with multiple encrypted fields for different authorized parties
    struct Loan {
        address borrower;
        address lender;
        euint32 encryptedAmount;        // Visible to borrower and lender
        euint32 encryptedBorrowerFee;   // Only borrower can decrypt
        euint32 encryptedLenderEarnings; // Only lender can decrypt
        bool isFunded;
        uint256 createdAt;
    }

    address public platform;
    uint32 public currentLoanId;

    mapping(uint32 => Loan) public loans;

    event LoanRequested(uint32 indexed loanId, address indexed borrower);
    event LoanFunded(uint32 indexed loanId, address indexed lender);
    event DecryptionRequested(uint32 indexed loanId, address indexed requester);

    constructor() {
        platform = msg.sender;
        currentLoanId = 0;
    }

    /// @notice Borrower requests a loan
    /// @param _amount Loan amount requested
    /// @param _borrowerFee Fee amount borrower must pay
    /// @return loanId The ID of the created loan
    function requestLoan(uint32 _amount, uint32 _borrowerFee)
        external
        returns (uint32 loanId)
    {
        require(_amount > 0, "Amount must be greater than 0");

        currentLoanId++;
        loanId = currentLoanId;

        // Create encrypted amount - both borrower and future lender can access
        euint32 encAmount = FHE.asEuint32(_amount);
        FHE.allowThis(encAmount);
        FHE.allow(encAmount, msg.sender); // Borrower can decrypt

        // Create encrypted borrower fee - only borrower can decrypt
        euint32 encBorrowerFee = FHE.asEuint32(_borrowerFee);
        FHE.allowThis(encBorrowerFee);
        FHE.allow(encBorrowerFee, msg.sender); // Only borrower

        // Lender earnings will be set when loan is funded
        euint32 encLenderEarnings = FHE.asEuint32(0);
        FHE.allowThis(encLenderEarnings);

        loans[loanId] = Loan({
            borrower: msg.sender,
            lender: address(0),
            encryptedAmount: encAmount,
            encryptedBorrowerFee: encBorrowerFee,
            encryptedLenderEarnings: encLenderEarnings,
            isFunded: false,
            createdAt: block.timestamp
        });

        emit LoanRequested(loanId, msg.sender);
        return loanId;
    }

    /// @notice Lender funds a loan
    /// @param _loanId The ID of the loan to fund
    /// @param _lenderEarnings Expected earnings for the lender
    /// @dev Grants lender access to decrypt loan amount and their earnings
    function fundLoan(uint32 _loanId, uint32 _lenderEarnings) external {
        Loan storage loan = loans[_loanId];
        require(!loan.isFunded, "Loan already funded");
        require(loan.borrower != msg.sender, "Cannot fund own loan");

        loan.lender = msg.sender;
        loan.isFunded = true;

        // Grant lender permission to decrypt loan amount
        FHE.allow(loan.encryptedAmount, msg.sender);

        // Set and grant permission for lender earnings
        euint32 encEarnings = FHE.asEuint32(_lenderEarnings);
        FHE.allowThis(encEarnings);
        FHE.allow(encEarnings, msg.sender); // Only lender can decrypt their earnings

        loan.encryptedLenderEarnings = encEarnings;

        emit LoanFunded(_loanId, msg.sender);
    }

    /// @notice Borrower retrieves their encrypted loan amount for decryption
    /// @param _loanId The ID of the loan
    /// @return encryptedAmount The encrypted amount (borrower can decrypt client-side)
    /// @dev Only borrower can call this - demonstrates user-specific decryption pattern
    function getBorrowerLoanAmount(uint32 _loanId)
        external
        view
        returns (euint32 encryptedAmount)
    {
        Loan storage loan = loans[_loanId];
        require(msg.sender == loan.borrower, "Only borrower can access");

        emit DecryptionRequested(_loanId, msg.sender);

        // Borrower can decrypt this because FHE.allow was called for them
        return loan.encryptedAmount;
    }

    /// @notice Borrower retrieves their encrypted fee for decryption
    /// @param _loanId The ID of the loan
    /// @return encryptedFee The encrypted fee (only borrower can decrypt)
    /// @dev Demonstrates exclusive access - only borrower, not even lender
    function getBorrowerFee(uint32 _loanId)
        external
        view
        returns (euint32 encryptedFee)
    {
        Loan storage loan = loans[_loanId];
        require(msg.sender == loan.borrower, "Only borrower can access");

        // Only borrower can decrypt this - lender cannot see it
        return loan.encryptedBorrowerFee;
    }

    /// @notice Lender retrieves encrypted loan amount for decryption
    /// @param _loanId The ID of the loan
    /// @return encryptedAmount The encrypted amount (lender can decrypt client-side)
    /// @dev Only lender can call this after funding
    function getLenderLoanAmount(uint32 _loanId)
        external
        view
        returns (euint32 encryptedAmount)
    {
        Loan storage loan = loans[_loanId];
        require(msg.sender == loan.lender, "Only lender can access");
        require(loan.isFunded, "Loan not funded yet");

        emit DecryptionRequested(_loanId, msg.sender);

        // Lender can decrypt this because FHE.allow was called when they funded
        return loan.encryptedAmount;
    }

    /// @notice Lender retrieves their encrypted earnings for decryption
    /// @param _loanId The ID of the loan
    /// @return encryptedEarnings The encrypted earnings (only lender can decrypt)
    /// @dev Demonstrates exclusive access - only lender, not borrower
    function getLenderEarnings(uint32 _loanId)
        external
        view
        returns (euint32 encryptedEarnings)
    {
        Loan storage loan = loans[_loanId];
        require(msg.sender == loan.lender, "Only lender can access");
        require(loan.isFunded, "Loan not funded yet");

        // Only lender can decrypt their earnings - borrower cannot see it
        return loan.encryptedLenderEarnings;
    }

    /// @notice Platform retrieves all encrypted data for a loan
    /// @param _loanId The ID of the loan
    /// @return amount Encrypted amount
    /// @return borrowerFee Encrypted borrower fee
    /// @return lenderEarnings Encrypted lender earnings
    /// @dev Platform has god-mode access for management purposes
    function getPlatformView(uint32 _loanId)
        external
        view
        returns (euint32 amount, euint32 borrowerFee, euint32 lenderEarnings)
    {
        require(msg.sender == platform, "Only platform");

        Loan storage loan = loans[_loanId];

        // Platform can access all encrypted data for dispute resolution,
        // auditing, and platform management
        return (
            loan.encryptedAmount,
            loan.encryptedBorrowerFee,
            loan.encryptedLenderEarnings
        );
    }

    /// @notice Get public loan information
    /// @param _loanId The ID of the loan
    /// @return borrower The borrower address
    /// @return lender The lender address
    /// @return isFunded Whether loan is funded
    /// @return createdAt Creation timestamp
    function getLoanInfo(uint32 _loanId)
        external
        view
        returns (
            address borrower,
            address lender,
            bool isFunded,
            uint256 createdAt
        )
    {
        Loan storage loan = loans[_loanId];
        return (loan.borrower, loan.lender, loan.isFunded, loan.createdAt);
    }
}
