// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @title PatientRecord - a single patient's on-chain register
/// @notice Owned by exactly one address (set at deploy). Stores an ordered list
///         of hashes of the *decrypted, canonical FHIR JSON* (NOT ciphertext),
///         plus an optional L2 chainId for your own bookkeeping.
contract PatientRecord {
    /// @dev The one and only controller of this record. Set once; never changes.
    address public immutable owner;

    /// @dev Append-only sequence number: 1, 2, 3, ...
    uint64 public seq;

    /// @dev seq => hash(plaintext FHIR JSON)
    mapping(uint64 => bytes32) public contentHashAt;

    /// @dev seq => EIP-155 chainId of the L2 used for storage (0 if you prefer not to disclose)
    mapping(uint64 => uint32) public l2ChainIdAt;

    /// @dev Emitted whenever a new entry is appended
    event Anchored(uint64 indexed seq, bytes32 indexed contentHash, uint32 l2ChainId);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @param _owner The patient address that will control this record
    constructor(address _owner) {
        require(_owner != address(0), "owner=0");
        owner = _owner; // immutable: cannot be changed later
    }

    /// @notice Append one entry (auto-assigns the next sequence number).
    /// @param contentHash Hash of the *decrypted, canonical FHIR JSON* (plaintext)
    /// @param l2ChainId   EIP-155 chain id for the L2 you used (set 0 to keep private)
    /// @return s The new sequence number for this entry
    function anchor(bytes32 contentHash, uint32 l2ChainId)
        external
        onlyOwner
        returns (uint64 s)
    {
        s = ++seq;                           // auto-increment
        contentHashAt[s] = contentHash;      // store plaintext hash
        l2ChainIdAt[s]   = l2ChainId;        // optional bookkeeping
        emit Anchored(s, contentHash, l2ChainId);
    }

    /// @notice Convenience read for UIs
    function getAt(uint64 s) external view returns (bytes32 contentHash, uint32 l2ChainId) {
        contentHash = contentHashAt[s];
        l2ChainId   = l2ChainIdAt[s];
    }
}
