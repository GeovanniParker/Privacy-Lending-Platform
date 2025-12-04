// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Lending Access Control Example
/// @notice Demonstrates FHE access control patterns for encrypted loan amounts
/// @dev Shows proper usage of FHE.allow() and FHE.allowThis()
/// @chapter access-control
contract LendingAccessControl is SepoliaConfig {

    /// @notice Loan structure with encrypted amount
    struct Loan {
        address borrower;
        euint32 encryptedAmount;     // Encrypted loan amount
        bool isActive;
        uint256 createdAt;
    }

    /// @notice Platform administrator
    address public platform;

    /// @notice Current loan ID counter
    uint32 public currentLoanId;

    /// @notice Mapping of loan IDs to loan data
    mapping(uint32 => Loan) public loans;

    /// @notice Event emitted when a loan is created
    event LoanCreated(uint32 indexed loanId, address indexed borrower, uint256 timestamp);

    /// @notice Event emitted when access is granted
    event AccessGranted(uint32 indexed loanId, address indexed user);

    modifier onlyPlatform() {
        require(msg.sender == platform, "Only platform can call this");
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

    /// @notice Create a new loan with encrypted amount
    /// @param _amount The encrypted loan amount (as uint32 for simplicity)
    /// @dev Demonstrates proper ACL setup with FHE.allowThis() and FHE.allow()
    function createLoan(uint32 _amount) external returns (uint32) {
        require(_amount > 0, "Amount must be greater than 0");

        currentLoanId++;

        // Convert plaintext to encrypted value
        // In production, this would come from an encrypted input
        euint32 encAmount = FHE.asEuint32(_amount);

        // CRITICAL: Grant permission to contract itself to perform operations
        // This must be done before any FHE operations on this value
        FHE.allowThis(encAmount);

        // CRITICAL: Grant permission to the borrower to decrypt their own amount
        // This allows the borrower to view their loan amount later
        FHE.allow(encAmount, msg.sender);

        loans[currentLoanId] = Loan({
            borrower: msg.sender,
            encryptedAmount: encAmount,
            isActive: true,
            createdAt: block.timestamp
        });

        emit LoanCreated(currentLoanId, msg.sender, block.timestamp);

        return currentLoanId;
    }

    /// @notice Grant access to encrypted loan amount for a specific user
    /// @param _loanId The ID of the loan
    /// @param _user The address to grant access to
    /// @dev Demonstrates how to grant access to additional parties (e.g., lender)
    function grantAccess(uint32 _loanId, address _user)
        external
        onlyPlatform
        loanExists(_loanId)
    {
        Loan storage loan = loans[_loanId];

        // Grant the user permission to access the encrypted amount
        // This is useful when a lender funds the loan and needs to see the amount
        FHE.allow(loan.encryptedAmount, _user);

        emit AccessGranted(_loanId, _user);
    }

    /// @notice Get encrypted loan amount (only for authorized users)
    /// @param _loanId The ID of the loan
    /// @return The encrypted amount (only decryptable by authorized addresses)
    /// @dev Access control is enforced by the ACL system
    function getEncryptedAmount(uint32 _loanId)
        external
        view
        loanExists(_loanId)
        returns (euint32)
    {
        Loan storage loan = loans[_loanId];

        // Only borrower, platform, and explicitly granted addresses can access
        // The ACL system enforces this automatically when trying to decrypt
        require(
            msg.sender == loan.borrower || msg.sender == platform,
            "Not authorized to access this loan"
        );

        return loan.encryptedAmount;
    }

    /// @notice Check if a loan exists and is active
    /// @param _loanId The ID of the loan
    /// @return borrower The borrower's address
    /// @return isActive Whether the loan is active
    /// @return createdAt Creation timestamp
    function getLoanInfo(uint32 _loanId)
        external
        view
        loanExists(_loanId)
        returns (address borrower, bool isActive, uint256 createdAt)
    {
        Loan storage loan = loans[_loanId];
        return (loan.borrower, loan.isActive, loan.createdAt);
    }

    /// @notice Deactivate a loan
    /// @param _loanId The ID of the loan
    /// @dev Platform can deactivate loans for management purposes
    function deactivateLoan(uint32 _loanId) external onlyPlatform loanExists(_loanId) {
        loans[_loanId].isActive = false;
    }

    /// @notice Transfer platform ownership
    /// @param _newPlatform The new platform administrator
    function transferPlatform(address _newPlatform) external onlyPlatform {
        require(_newPlatform != address(0), "Invalid address");
        platform = _newPlatform;
    }
}
