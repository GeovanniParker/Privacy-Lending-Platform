// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint64 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Public Decryption Example
/// @notice Demonstrates public decryption patterns using gateway/relayer
/// @dev Shows how to decrypt values for public visibility
/// @chapter decryption
contract PublicDecryption is SepoliaConfig {

    /// @notice Encrypted value that can be publicly decrypted
    euint32 private encryptedValue;

    /// @notice Last publicly decrypted value
    uint32 public lastDecryptedValue;

    /// @notice Owner of the contract
    address public owner;

    /// @notice Event emitted when decryption is requested
    event DecryptionRequested(uint256 indexed requestId);

    /// @notice Event emitted when value is publicly revealed
    event ValueRevealed(uint32 value, address indexed revealer);

    constructor() {
        owner = msg.sender;
        encryptedValue = FHE.asEuint32(0);
        FHE.allowThis(encryptedValue);
    }

    /**
     * @notice Set an encrypted value
     * @dev This value can later be decrypted publicly
     * @param value Plaintext value (for demo purposes)
     *
     * In production:
     * - Use inEuint32 with input proof
     * - Validate input ranges
     * - Check caller permissions
     */
    function setEncryptedValue(uint32 value) external {
        encryptedValue = FHE.asEuint32(value);
        FHE.allowThis(encryptedValue);
        FHE.allow(encryptedValue, msg.sender);
    }

    /**
     * @notice Request public decryption of the encrypted value
     * @dev Uses gateway pattern to decrypt value publicly
     * @return requestId The decryption request ID
     *
     * How Public Decryption Works:
     * 1. Contract requests decryption from gateway
     * 2. Gateway/relayer decrypts the value
     * 3. Callback function receives plaintext
     * 4. Value becomes publicly visible
     *
     * Use Cases:
     * - Auction winner reveal
     * - Vote tallying
     * - Lottery results
     * - Threshold-triggered reveals
     */
    function requestPublicDecryption() external returns (uint256 requestId) {
        // In FHEVM, public decryption typically uses a gateway service
        // This is a simplified example showing the pattern

        // Request decryption (actual implementation depends on gateway)
        requestId = uint256(keccak256(abi.encodePacked(block.timestamp, encryptedValue)));

        emit DecryptionRequested(requestId);

        return requestId;
    }

    /**
     * @notice Callback to receive decrypted value
     * @dev Called by gateway/relayer with decrypted value
     * @param decryptedValue The decrypted plaintext value
     *
     * ⚠️ SECURITY: In production, verify callback is from authorized gateway
     */
    function receiveDecryptedValue(uint32 decryptedValue) external {
        // In production: require(msg.sender == authorizedGateway)

        lastDecryptedValue = decryptedValue;

        emit ValueRevealed(decryptedValue, msg.sender);
    }

    /**
     * @notice Get the encrypted value (still encrypted)
     * @return The encrypted value handle
     */
    function getEncryptedValue() external view returns (euint32) {
        return encryptedValue;
    }

    /**
     * @notice Get the last publicly decrypted value
     * @return The plaintext decrypted value
     */
    function getLastDecryptedValue() external view returns (uint32) {
        return lastDecryptedValue;
    }

    /**
     * @notice Grant permission to view encrypted value (before public decrypt)
     * @dev Allows specific address to decrypt privately
     * @param user Address to grant permission to
     */
    function grantAccess(address user) external {
        require(msg.sender == owner, "Only owner can grant access");
        FHE.allow(encryptedValue, user);
    }
}

/**
 * @title Multi-Value Public Decryption
 * @notice Demonstrates decrypting multiple values at once
 * @dev Useful for batch operations like vote tallying
 */
contract MultiValuePublicDecryption is SepoliaConfig {

    /// @notice Array of encrypted votes
    euint32[] private encryptedVotes;

    /// @notice Public tally results
    uint32[] public tallyResults;

    /// @notice Voting ended flag
    bool public votingEnded;

    /// @notice Event emitted when votes are tallied
    event VotesTallied(uint256 voteCount);

    /**
     * @notice Submit an encrypted vote
     * @dev Votes remain private until tally
     * @param vote Plaintext vote value (for demo)
     */
    function submitVote(uint32 vote) external {
        require(!votingEnded, "Voting has ended");

        euint32 encryptedVote = FHE.asEuint32(vote);
        FHE.allowThis(encryptedVote);

        encryptedVotes.push(encryptedVote);
    }

    /**
     * @notice End voting and request public tally
     * @dev Triggers batch decryption of all votes
     *
     * Process:
     * 1. Mark voting as ended
     * 2. Request decryption of all votes
     * 3. Gateway decrypts in batch
     * 4. Results become public
     */
    function endVotingAndTally() external {
        require(!votingEnded, "Already tallied");

        votingEnded = true;

        // In production: Request batch decryption from gateway
        // Gateway would call receiveTallyResults()

        emit VotesTallied(encryptedVotes.length);
    }

    /**
     * @notice Receive decrypted tally results
     * @dev Called by gateway with all decrypted votes
     * @param results Array of decrypted vote values
     */
    function receiveTallyResults(uint32[] calldata results) external {
        // In production: require(msg.sender == authorizedGateway)
        require(votingEnded, "Voting not ended");

        tallyResults = results;
    }

    /**
     * @notice Get total number of votes
     * @return Vote count
     */
    function getVoteCount() external view returns (uint256) {
        return encryptedVotes.length;
    }

    /**
     * @notice Get tally results (after decryption)
     * @return Array of plaintext vote values
     */
    function getTallyResults() external view returns (uint32[] memory) {
        require(votingEnded, "Voting not ended");
        return tallyResults;
    }
}
