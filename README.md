# protocol-medrec — Prometheus Chains
Solidity contracts for **patient-owned medical records**:
- L1 (Ethereum): append-only **PatientRecord** timeline (content-hash only)
- L2 (Base): encrypted storage by **secret tag** in a minimal **Vault**

![License](https://img.shields.io/badge/license-Apache--2.0-blue)

## Why
Healthcare’s data silos block trust and portability. Here the **patient** is the steward of a single source of truth:
- L1: integrity + ordering = `seq`, `contentHash`
- L2: storage + privacy = `tag → ciphertext`
- Device: does the crypto; plaintext never leaves the device

## Contracts
- `PatientRecord.sol` — owner-only append; `anchor(bytes32 contentHash, uint32 l2ChainId)`; `seq`, `contentHashAt(i)`
- `PatientRecordFactory.sol` — one record per address; `createRecord()`, `recordOf(address)`
- `EventVaultHashOnly.sol` (L2) — `put(bytes ciphertext, bytes16 tag) → bytes32 envelopeId`, plus reads by tag / id

## Design highlights
- **Anchor-first**: canonicalize FHIR JSON (stable stringify) → `sha256` → `contentHash` → append to L1.
- **Deterministic crypto** (done off-chain):  
  One EIP-712 signature (session-only) → derive `{tag(16), key(32), nonce(12)}` from `(root, recordAddr, index i)`; encrypt plaintext with **AES-256-GCM**; store to L2 by `tag`.
- **Restore**: iterate `i = 1..seq`, re-derive `{tag,key,nonce}`, fetch ciphertext, decrypt locally, verify `sha256(pt) == contentHashAt(i)`.

## Quickstart

### Foundry
```bash
forge build
forge test -vv
