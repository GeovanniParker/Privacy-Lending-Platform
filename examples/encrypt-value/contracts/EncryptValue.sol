// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint8, euint32, euint64, inEuint8, inEuint32, inEuint64 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Encrypt Value - Encryption Patterns
/// @notice Demonstrates various encryption patterns for different data types
/// @dev Shows how to encrypt single values and handle input proofs correctly
/// @chapter encryption
contract EncryptValue is SepoliaConfig {

    /// @notice Storage for encrypted 8-bit value
    euint8 private encryptedSmallValue;

    /// @notice Storage for encrypted 32-bit value
    euint32 private encryptedMediumValue;

    /// @notice Storage for encrypted 64-bit value
    euint64 private encryptedLargeValue;

    /// @notice Mapping of users to their encrypted balances
    mapping(address => euint32) private userBalances;

    /// @notice Event emitted when value is encrypted
    event ValueEncrypted(address indexed user, string valueType);

    /**
     * @notice Encrypt and store a small value (euint8)
     * @dev Demonstrates encryption of 8-bit values (0-255)
     * @param inputValue Encrypted input value
     * @param inputProof Proof of correct encryption
     *
     * Use Cases:
     * - Age (0-120)
     * - Percentage (0-100)
     * - Small counters
     * - Boolean-like values
     */
    function encryptSmallValue(
        inEuint8 calldata inputValue,
        bytes calldata inputProof
    ) external {
        // Convert external encrypted input to internal type
        euint8 value = FHE.asEuint8(inputValue, inputProof);

        // Store encrypted value
        encryptedSmallValue = value;

        // ✅ CRITICAL: Always grant permissions after storing
        FHE.allowThis(encryptedSmallValue);
        FHE.allow(encryptedSmallValue, msg.sender);

        emit ValueEncrypted(msg.sender, "euint8");
    }

    /**
     * @notice Encrypt and store a medium value (euint32)
     * @dev Demonstrates encryption of 32-bit values (0-4,294,967,295)
     * @param inputValue Encrypted input value
     * @param inputProof Proof of correct encryption
     *
     * Use Cases:
     * - Loan amounts
     * - Account balances
     * - Timestamps
     * - Counters
     */
    function encryptMediumValue(
        inEuint32 calldata inputValue,
        bytes calldata inputProof
    ) external {
        euint32 value = FHE.asEuint32(inputValue, inputProof);
        encryptedMediumValue = value;

        FHE.allowThis(encryptedMediumValue);
        FHE.allow(encryptedMediumValue, msg.sender);

        emit ValueEncrypted(msg.sender, "euint32");
    }

    /**
     * @notice Encrypt and store a large value (euint64)
     * @dev Demonstrates encryption of 64-bit values
     * @param inputValue Encrypted input value
     * @param inputProof Proof of correct encryption
     *
     * Use Cases:
     * - Large financial amounts
     * - High-precision calculations
     * - Accumulated totals
     */
    function encryptLargeValue(
        inEuint64 calldata inputValue,
        bytes calldata inputProof
    ) external {
        euint64 value = FHE.asEuint64(inputValue, inputProof);
        encryptedLargeValue = value;

        FHE.allowThis(encryptedLargeValue);
        FHE.allow(encryptedLargeValue, msg.sender);

        emit ValueEncrypted(msg.sender, "euint64");
    }

    /**
     * @notice Encrypt from plaintext value (for testing/initialization)
     * @dev Shows how to convert plaintext to encrypted type
     * @param plainValue Plaintext value to encrypt
     *
     * ⚠️ WARNING: Only use this for:
     * - Contract initialization
     * - Testing
     * - Public constants
     *
     * ❌ NEVER use for user-submitted sensitive data
     */
    function encryptFromPlaintext(uint32 plainValue) external {
        // Convert plaintext to encrypted
        encryptedMediumValue = FHE.asEuint32(plainValue);

        FHE.allowThis(encryptedMediumValue);
        FHE.allow(encryptedMediumValue, msg.sender);

        emit ValueEncrypted(msg.sender, "plaintext-to-euint32");
    }

    /**
     * @notice Store user's encrypted balance
     * @dev Demonstrates per-user encrypted storage
     * @param inputBalance Encrypted balance value
     * @param inputProof Proof of correct encryption
     *
     * Key Pattern: Each user has their own encrypted value
     */
    function setUserBalance(
        inEuint32 calldata inputBalance,
        bytes calldata inputProof
    ) external {
        euint32 balance = FHE.asEuint32(inputBalance, inputProof);
        userBalances[msg.sender] = balance;

        // Grant permissions
        FHE.allowThis(userBalances[msg.sender]);
        FHE.allow(userBalances[msg.sender], msg.sender);

        emit ValueEncrypted(msg.sender, "user-balance");
    }

    /**
     * @notice Get encrypted small value
     * @return Encrypted 8-bit value
     */
    function getSmallValue() external view returns (euint8) {
        return encryptedSmallValue;
    }

    /**
     * @notice Get encrypted medium value
     * @return Encrypted 32-bit value
     */
    function getMediumValue() external view returns (euint32) {
        return encryptedMediumValue;
    }

    /**
     * @notice Get encrypted large value
     * @return Encrypted 64-bit value
     */
    function getLargeValue() external view returns (euint64) {
        return encryptedLargeValue;
    }

    /**
     * @notice Get user's encrypted balance
     * @param user Address of the user
     * @return Encrypted balance
     */
    function getUserBalance(address user) external view returns (euint32) {
        return userBalances[user];
    }

    /**
     * @notice Grant access to encrypted values
     * @dev Allows another address to decrypt the values
     * @param user Address to grant access to
     */
    function grantAccessToValues(address user) external {
        FHE.allow(encryptedSmallValue, user);
        FHE.allow(encryptedMediumValue, user);
        FHE.allow(encryptedLargeValue, user);
    }
}
