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

The UI is terminal-styled and has three views: a boot-screen **home**, the **simulator**, and an **about** page that explains the economics.

**What you are testing**

- Whether validators will stake capital for a 1.0% commission
- Whether projected APY justifies slashing risk
- How buyer-win and validator-win disputes affect profitability

**Demo flow**

1. From the home screen, click `[ enter simulator ]` (or the `simulator` tab in the header).
2. Click `Start Demo` to connect the mock wallet.
3. Take one or more validation jobs from the listings section.
4. Watch active stake, projected APY, realized earnings, and success rate update.
5. Use the dispute simulator to resolve a staked listing as either buyer-win or validator-win.

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

`contracts/lib/` is gitignored, so install the pinned dependencies locally (these match CI). Remappings for `forge-std` and `@openzeppelin/contracts` are committed in `contracts/remappings.txt`.

```bash
cd contracts
forge install foundry-rs/forge-std@v1.9.4
forge install OpenZeppelin/openzeppelin-contracts@v5.1.0
```

### Test The Contracts

```bash
forge build
forge test -vv
forge test --gas-report
```

> Note: the suite compiles and most tests pass, including the `InsurancePool`
> suite. A couple of `BoraMarketplace` escrow cases currently fail — see
> [ROADMAP.md](ROADMAP.md).

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

- Validator economics simulation UI (terminal-styled home, simulator, and about views)
- Core Solidity contracts
- Unit, integration, and fuzz coverage for major contract flows, plus a dedicated `InsurancePool` suite
- Frontend, contract, and Slither CI workflows (frontend workflow is green)
- Economics and architecture docs

### In Progress / Still Missing

- Two `BoraMarketplace` escrow test cases to fix
- Slither findings to triage
- Backend agent API
- Live wallet/on-chain frontend integration
- Testnet deployment
- External audit and deeper security hardening
- Production dispute operations and reviewer tooling

See [ROADMAP.md](ROADMAP.md) for the full backlog and status of each item.

---

## Next Actions

1. Resolve the failing `BoraMarketplace` escrow tests and triage Slither findings.
2. Expand dispute and insurance edge-case tests.
3. Add a minimal backend API for agent identity, listing reads, validation bids, dispute evidence, and trust signals.
4. Prepare Base Sepolia deployment only after hardening and internal review.

---

Built by @iammcqwory - Bora International Group
