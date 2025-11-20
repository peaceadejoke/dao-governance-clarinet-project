A decentralized autonomous organization (DAO) governance system built with Clarity smart contracts on the Stacks blockchain.

## Overview

This project implements a complete DAO governance framework with two primary contracts:

1. **Governance Contract** - Manages proposals, voting, and execution
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

## Project Structure
```
dao-governance-clarinet-project/
├── contracts/
│   ├── governance.clar           # Core governance logic
│   └── governance-token.clar     # Voting token (SIP-010)
├── tests/
│   └── governance_test.ts        # Contract tests
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

Example commands:
```clarity
;; Create a proposal
(contract-call? .governance create-proposal u"Increase treasury allocation" u100)

;; Vote on proposal #1
(contract-call? .governance vote u1 true)

;; Check proposal status
(contract-call? .governance get-proposal u1)
```

## Error Codes

### Governance Contract
- `404` - Proposal not found
- `408` - Proposal not ended yet
- `409` - Already voted on this proposal
- `410` - Proposal failed

### Governance Token Contract
- `401` - Not authorized
- `402` - Insufficient balance
- `403` - Invalid amount

## License

MIT License
EOF
Step 3: Create the Token Contract
