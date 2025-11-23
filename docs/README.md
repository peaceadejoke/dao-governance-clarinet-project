# DAO Governance System - Phase 3

A decentralized autonomous organization (DAO) governance system built with Clarity smart contracts on the Stacks blockchain.

## Overview

This project implements a complete DAO governance framework with enhanced security features and advanced functionality:

1. **Governance Contract** - Manages proposals, voting, and execution with security measures
2. **Governance Token Contract** - SIP-010 fungible token for voting weights

## Features

### Phase 1 ✅
- Create governance proposals with descriptions and durations
- Vote on active proposals (yes/no)
- Prevent double voting
- Check proposal results
- Execute passed proposals after voting period ends

### Phase 2 ✅
- SIP-010 compliant governance token (DGOV)
- Token-based voting weights
- Mint and transfer functionality
- Total supply: 1,000,000 DGOV tokens

### Phase 3 ✅ (Enhanced Security & Features)

#### 🔐 Security Enhancements
- **Quorum Requirements**: Minimum vote threshold (100 tokens) must be met
- **Approval Threshold**: 51% approval rate required for proposals to pass
- **Time-locks**: Configurable execution delays prevent immediate execution
- **Two-Step Execution**: Queue execution, then execute after delay period
- **Proposal Cancellation**: Proposers can cancel their active proposals
- **Duration Limits**: Min 10 blocks, max ~100 days (14,400 blocks)
- **Proposal Threshold**: Minimum token holdings required to create proposals

#### ⚡ New Functionality
- **Weighted Voting**: Votes weighted by token balance
- **Vote Delegation**: Delegate voting power to another address
- **Proposal Categories**: Organize proposals by type (Treasury, Parameter, Upgrade, etc.)
- **Enhanced Statistics**: 
  - Real-time approval rates
  - Quorum tracking
  - Time remaining calculations
  - Total vote weight tracking
- **Execution Queue System**: Time-locked execution with `queue-execution` → `execute-proposal`
- **Proposal States**: Track canceled, executed, and active states

## Project Structure

```
dao-governance-clarinet-project/
├── contracts/
│   ├── governance.clar           # Enhanced governance logic (Phase 3)
│   └── governance-token.clar     # Voting token (SIP-010)
├── tests/
│   └── governance_test.ts        # Comprehensive tests
├── Clarinet.toml                 # Project configuration
└── README.md                     # This file
```

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js (for running tests)

### Running Tests
```bash
clarinet test
```

### Interactive Console
```bash
clarinet console
```

## Usage Examples

### Creating a Proposal
```clarity
;; Create a treasury proposal with 100-block voting period and 50-block execution delay
(contract-call? .governance create-proposal 
  u"Allocate 10,000 STX to marketing fund" 
  u100 
  u"Treasury"
  u50)
```

### Voting on a Proposal
```clarity
;; Vote YES on proposal #1 (vote weighted by token balance)
(contract-call? .governance vote u1 true)

;; Vote NO on proposal #1
(contract-call? .governance vote u1 false)
```

### Delegating Voting Power
```clarity
;; Delegate your votes to another address
(contract-call? .governance delegate-votes 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Revoke delegation
(contract-call? .governance revoke-delegation)
```

### Checking Proposal Status
```clarity
;; Get full proposal details
(contract-call? .governance get-proposal u1)

;; Get proposal statistics
(contract-call? .governance get-proposal-stats u1)

;; Check if proposal can be executed
(contract-call? .governance can-execute u1)

;; Get final results
(contract-call? .governance result u1)
```

### Executing a Proposal (Two-Step Process)
```clarity
;; Step 1: Queue the proposal for execution (after voting ends)
(contract-call? .governance queue-execution u1)

;; Step 2: Execute after time-lock expires
(contract-call? .governance execute-proposal u1)
```

### Canceling a Proposal
```clarity
;; Proposer can cancel their own active proposal
(contract-call? .governance cancel-proposal u1)
```

### Admin Functions
```clarity
;; Set the governance token contract address
(contract-call? .governance set-governance-token .governance-token)

;; Set minimum tokens required to create proposals
(contract-call? .governance set-proposal-threshold u5000)
```

## Security Model

### Proposal Lifecycle
1. **Creation** → Requires minimum token threshold
2. **Voting Period** → Start block to end block
3. **Vote Tallying** → Weighted by token holdings
4. **Quorum Check** → Must meet minimum participation
5. **Queue Execution** → Time-lock begins
6. **Execution** → After time-lock expires

### Protection Mechanisms
- ✅ Double-vote prevention
- ✅ Quorum requirements prevent low-participation passing
- ✅ Approval threshold ensures majority support
- ✅ Time-locks prevent instant execution attacks
- ✅ Proposal cancellation for proposers
- ✅ Duration limits prevent extremely long/short votes
- ✅ Token threshold prevents spam proposals

## Error Codes

### Governance Contract
- `401` - Not authorized
- `404` - Proposal not found
- `408` - Proposal not ended / Time requirement not met
- `409` - Already voted on this proposal
- `410` - Proposal failed
- `411` - Invalid duration
- `412` - Already executed
- `413` - Quorum not met
- `414` - Proposal still active
- `415` - Invalid token amount

### Governance Token Contract
- `401` - Not authorized
- `402` - Insufficient balance
- `403` - Invalid amount

## Configuration Constants

```clarity
MIN-QUORUM              u100    ;; Minimum total vote weight required
MIN-APPROVAL-PERCENT    u51     ;; Minimum 51% approval needed
min-proposal-threshold  u1000   ;; Min tokens to create proposal (configurable)
```

## Integration with Governance Token

The governance contract integrates with the SIP-010 token contract to:
- Check voter token balances for weighted voting
- Verify proposer meets minimum threshold
- Calculate voting power based on holdings

## Future Enhancements (Phase 4 Ideas)

- Treasury integration for on-chain fund management
- Multi-signature execution requirements
- Proposal dependencies (requires another proposal to pass)
- Vote snapshots at proposal creation
- Partial vote delegation by percentage
- Emergency pause functionality
- Proposal amendments before voting ends

## Testing

The project includes comprehensive tests covering:
- Proposal creation and validation
- Weighted voting mechanics
- Double-vote prevention
- Quorum and approval thresholds
- Time-lock execution flow
- Delegation functionality
- Edge cases and error conditions

Run tests with:
```bash
clarinet test
```

## License

MIT License

---

## Contributing

Contributions are welcome! Please ensure:
1. All tests pass
2. Security considerations are documented
3. Code follows Clarity best practices
4. New features include appropriate tests

## Resources

- [Clarity Language Reference](https://docs.stacks.co/clarity)
- [SIP-010 Fungible Token Standard](https://github.com/stacksgov/sips/blob/main/sips/sip-010/sip-010-fungible-token-standard.md)
- [Stacks Documentation](https://docs.stacks.co)
