# DAO Governance Contract (Stacks / Clarity)

This project implements a simple governance system for a DAO on the Stacks blockchain. It allows token holders—or any permitted voters—to create proposals, vote, and check results.

---

## Features

* Create proposals with descriptions and a duration.
* Vote "yes" or "no" on proposals.
* One vote per principal per proposal.
* Automatic vote tallying.
* Execution function that checks if a proposal passed.

---

## Project Structure

```
contracts/
  governance.clar
clarinet/
  Devnet.toml
tests/
  governance_tests.ts
Clarinet.toml
README.md
.gitignore
```

---

## Requirements

* Clarinet
* Node.js
* Git (optional)

Install Clarinet:

```bash
curl -sSfL https://deno.land/x/clarinet/install.sh | sh
```

Check:

```bash
clarinet --version
```

---

## Running the Project

### Start Devnet

```bash
clarinet devnet start
```

### Open Console

```bash
clarinet console
```

Interact:

```lisp
(contract-call? .governance create-proposal "Test Proposal" u10)
(contract-call? .governance vote u0 true)
(read-only? .governance get-proposal u0)
```

---

## Testing

```bash
clarinet test
```

---

## Contract Overview

### Data

* **proposals** map: proposer, description, votes, end-block
* **votes** map: prevents double voting

### Public Functions

* `create-proposal(description, duration)`
* `vote(id, choice)`
* `get-proposal(id)`
* `result(id)`
* `execute-proposal(id)`

---

## Possible Extensions

* Token-weighted voting via SIP‑010
* Quorum rules
* Proposal execution actions that call other contracts
* Proposal deposits or permissions
