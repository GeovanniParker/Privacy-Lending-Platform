// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, inEuint32 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title FHE Counter - Simple Encrypted Counter
/// @notice Demonstrates basic FHE operations with an encrypted counter
/// @dev Shows fundamental FHEVM patterns: encryption, arithmetic, and access control
/// @chapter basic
contract FHECounter is SepoliaConfig {

    /// @notice Encrypted counter value
    euint32 private _count;

    /// @notice Contract owner
    address public owner;

    /// @notice Event emitted when counter is incremented
    event CounterIncremented(address indexed user);

    /// @notice Event emitted when counter is decremented
    event CounterDecremented(address indexed user);

    /// @notice Event emitted when counter is reset
    event CounterReset(address indexed user);

    constructor() {
        owner = msg.sender;
        _count = FHE.asEuint32(0);
        FHE.allowThis(_count);
    }

    /// @notice Returns the encrypted count with proper access control
    /// @dev Only users with permission can decrypt this value
    /// @return The encrypted counter value
    function getCount() external view returns (euint32) {
        return _count;
    }

    /// @notice Increments the counter by an encrypted value
    /// @dev Demonstrates FHE.add() for encrypted addition
    /// @param inputValue Encrypted input value to add
    /// @param inputProof Proof of correct encryption
    function increment(inEuint32 calldata inputValue, bytes calldata inputProof) external {
        // Convert external encrypted input to internal encrypted type
        euint32 encryptedValue = FHE.asEuint32(inputValue, inputProof);

        // Perform encrypted addition
        _count = FHE.add(_count, encryptedValue);

        // Grant permissions for contract and user
        FHE.allowThis(_count);
        FHE.allow(_count, msg.sender);

        emit CounterIncremented(msg.sender);
    }

    /// @notice Decrements the counter by an encrypted value
    /// @dev Demonstrates FHE.sub() for encrypted subtraction
    /// @param inputValue Encrypted input value to subtract
    /// @param inputProof Proof of correct encryption
    function decrement(inEuint32 calldata inputValue, bytes calldata inputProof) external {
        // Convert external encrypted input to internal encrypted type
        euint32 encryptedValue = FHE.asEuint32(inputValue, inputProof);

        // Perform encrypted subtraction
        _count = FHE.sub(_count, encryptedValue);

        // Grant permissions for contract and user
        FHE.allowThis(_count);
        FHE.allow(_count, msg.sender);

        emit CounterDecremented(msg.sender);
    }

    /// @notice Increments counter by 1 (plaintext value)
    /// @dev Shows how to add plaintext values to encrypted data
    function incrementByOne() external {
        // Add plaintext 1 to encrypted counter
        _count = FHE.add(_count, FHE.asEuint32(1));

        // Update permissions
        FHE.allowThis(_count);
        FHE.allow(_count, msg.sender);

        emit CounterIncremented(msg.sender);
    }

    /// @notice Resets the counter to zero
    /// @dev Only owner can reset
    function reset() external {
        require(msg.sender == owner, "Only owner can reset");

        _count = FHE.asEuint32(0);
        FHE.allowThis(_count);

        emit CounterReset(msg.sender);
    }

    /// @notice Grants permission to view the counter
    /// @dev Allows specific address to decrypt the counter value
    /// @param user Address to grant permission to
    function grantAccess(address user) external {
        require(msg.sender == owner, "Only owner can grant access");
        FHE.allow(_count, user);
    }
}
