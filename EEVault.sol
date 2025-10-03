// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @title EventVaultHashOnly - Shared L2 store keyed by content hash (envelopeId)
/// @notice MVP: caller supplies ciphertext and a 16-byte searchable tag.
///         We store: envelopeId => ciphertext, and tag => envelopeId.
///         No numeric auto-ID, no timestamps, no sender tracking, no plaintext metadata.
contract EventVaultHashOnly {
    // envelopeId = keccak256(ciphertext)
    mapping(bytes32 => bytes)  private _ciphertextOf;    // envelopeId => ciphertext (variable length)
    mapping(bytes16 => bytes32) public  envelopeIdByTag; // tag => envelopeId (unique)

    event Stored(bytes16 indexed tag, bytes32 indexed envelopeId);

    error DuplicateTag(bytes16 tag);
    error DuplicateEnvelope(bytes32 envelopeId);
    error UnknownEnvelope(bytes32 envelopeId);

    /// @notice Store an encrypted container with a searchable tag.
    /// @param ciphertext Arbitrary-length encrypted bytes (no padding enforced in MVP).
    /// @param tag        16-byte pseudorandom identifier (derive off-chain; must be unique in this vault).
    /// @return envelopeId keccak256(ciphertext)
    function put(bytes calldata ciphertext, bytes16 tag)
        external
        returns (bytes32 envelopeId)
    {
        envelopeId = keccak256(ciphertext);

        if (envelopeIdByTag[tag] != bytes32(0)) revert DuplicateTag(tag);
        if (_ciphertextOf[envelopeId].length != 0) revert DuplicateEnvelope(envelopeId);

        _ciphertextOf[envelopeId] = ciphertext;
        envelopeIdByTag[tag] = envelopeId;

        emit Stored(tag, envelopeId);
    }

    // ---- Reads ----

    /// @notice Fetch ciphertext by its content-addressed id.
    function getCiphertext(bytes32 envelopeId) external view returns (bytes memory) {
        bytes memory ct = _ciphertextOf[envelopeId];
        if (ct.length == 0) revert UnknownEnvelope(envelopeId);
        return ct;
    }

    /// @notice Resolve tag -> envelopeId (returns 0x0 if unknown).
    function getEnvelopeIdByTag(bytes16 tag) external view returns (bytes32) {
        return envelopeIdByTag[tag];
    }

    /// @notice Convenience: fetch ciphertext directly by tag (empty if unknown).
    function getCiphertextByTag(bytes16 tag) external view returns (bytes memory) {
        bytes32 id = envelopeIdByTag[tag];
        return _ciphertextOf[id]; // ok to return empty if unknown
    }

    /// @notice Check presence by envelopeId.
    function exists(bytes32 envelopeId) external view returns (bool) {
        return _ciphertextOf[envelopeId].length != 0;
    }
}
