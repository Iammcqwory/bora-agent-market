# Bora Agent Market - Quick Start Guide

> Get the current prototype running and understand what is ready versus what still needs hardening.

---

## Project Structure

```text
bora-agent-market/
├── validator-sim/        # Phase 0: Economics simulation (React + Vite)
├── contracts/            # Phase 1: Smart contracts (Solidity + Foundry)
├── backend/              # Phase 2: Agent API scaffold target (not built yet)
└── docs/                 # Strategy and architecture docs
    ├── economics-analysis.md
    └── architecture.md
```

---

## Phase 0: Test the Economics

**Time**: 5 minutes

```bash
cd validator-sim
npm install
npm run dev
```

Open <http://localhost:5173>.

**What you are testing**

- Whether validators will stake capital for a 1.0% commission
- Whether projected APY justifies slashing risk
- How buyer-win and validator-win disputes affect profitability

**Demo flow**

1. Click `Start Demo` or `Connect Mock Wallet`.
2. Take one or more validation jobs from the listings section.
3. Watch active stake, projected APY, realized earnings, and success rate update.
4. Use the dispute simulator to resolve a staked listing as either buyer-win or validator-win.

**Useful commands**

```bash
npm run lint
npm run test
npm run build
```

---

## Phase 1: Run the Contracts

The four core contracts are implemented:

- `BoraStaking.sol`
- `BoraMarketplace.sol`
- `BoraDispute.sol`
- `InsurancePool.sol`

They are still pre-deployment and should be treated as hardening-stage code.

### Prerequisites

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Install Contract Dependencies

```bash
cd contracts
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts
```

### Test The Contracts

```bash
forge build
forge test -vv
forge test --gas-report
```

---

## Read The Strategy Docs

### Economics Analysis

`docs/economics-analysis.md`

Covers validator incentives, stake tiers, insurance assumptions, APY targets, and marketplace unit economics.

### Architecture

`docs/architecture.md`

Covers the contract system, dispute flow, Base L2 deployment direction, and security considerations.

---

## Key Metrics

| Metric | Value | Why It Matters |
|---|---:|---|
| Validator target APY | 25-40% | Must beat lower-risk capital alternatives |
| Break-even GMV | ~$880K/month | Rough scale target for sustainability |
| Validators needed | ~50 active | Supports concurrent listing coverage |
| Stake requirement | 20-75% of item value | Keeps validator capital at risk |

---

## Current State

### Complete

- Validator economics simulation UI
- Core Solidity contracts
- Unit, integration, and fuzz coverage for major contract flows
- Frontend, contract, and Slither CI workflows
- Economics and architecture docs

### Still Missing

- Backend agent API
- Live wallet/on-chain frontend integration
- Testnet deployment
- External audit and deeper security hardening
- Production dispute operations and reviewer tooling

---

## Next Actions

1. Keep frontend and contract CI green.
2. Expand dispute and insurance edge-case tests.
3. Add a minimal backend API for agent identity, listing reads, validation bids, dispute evidence, and trust signals.
4. Prepare Base Sepolia deployment only after hardening and internal review.

---

Built by @iammcqwory - Bora International Group
