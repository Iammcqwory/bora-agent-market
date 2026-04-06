# Bora Agent Market - Quick Start Guide

> Get the entire project running in 10 minutes

---

## Project Structure

```
bora-agent-market/
├── validator-sim/        ← Phase 0: Economics simulation (React app)
├── contracts/            ← Phase 1: Smart contracts (Solidity + Foundry)
├── backend/              ← Phase 2: Agent API (TBD)
└── docs/                 ← Strategy & architecture docs
    ├── economics-analysis.md
    ├── knowledge-base.md
    └── architecture.md
```

---

## Phase 0: Test the Economics (Validator Simulation)

**Time**: 5 minutes

```bash
cd validator-sim
npm install
npm run dev
```

Open http://localhost:5173

**What you're testing**: 
- Will validators stake capital for 1.0% commission?
- Does the APY justify the slashing risk?
- How do disputes affect profitability?

**Actions**:
1. Click "Connect Wallet" (mock connection)
2. Stake on multiple items ($10-$1,125 stakes)
3. Watch dashboard update (total staked, commissions, APY)
4. Use Dispute Simulator to test slashing

**Expected result**: APY should reach 25-40% with multiple stakes and 95% success rate.

---

## Phase 1: Run the Smart Contracts (Staking Engine)

**Time**: 5 minutes

### Prerequisites
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Test the Contracts
```bash
cd contracts
forge install OpenZeppelin/openzeppelin-contracts
forge build
forge test -vv
```

**Expected output**:
```
Running 17 tests...
[PASS] test_StakeRequirement_Tier1
[PASS] test_LockStake_Success
[PASS] test_ReleaseStake_Success
[PASS] test_SlashStake_Success
...
All tests passed ✓
```

### Check Gas Usage
```bash
forge test --gas-report
```

**Target**: <100k gas per stake operation

---

## Read the Strategy Docs

### 1. Economics Analysis (`/docs/economics-analysis.md`)
The math behind validator incentives. Answers:
- Why 1.0% commission?
- Why tiered stakes (20-75%)?
- How does the insurance pool work?
- What APY do validators need to beat DeFi?

### 2. Architecture (`/docs/architecture.md`)
Smart contract design. Covers:
- 4 contract system (Staking, Marketplace, Dispute, Insurance)
- Gas optimization strategies
- Security considerations
- Testing & deployment plan

### 3. Knowledge Base (`/docs/knowledge-base.md`)
Full project vision. Includes:
- Trust-as-a-Protocol philosophy
- Anti-collusion mechanisms
- Revenue model & unit economics
- Roadmap to break-even ($880K GMV/month)

---

## Key Metrics to Understand

| Metric | Value | Why It Matters |
|---|---|---|
| Validator Target APY | 25-40% | Must beat DeFi lending (5-8%) |
| Break-even GMV | $880K/month | 100 tx/day at $300 avg |
| LTV:CAC | 2.14× | Needs work (target 3×+) |
| Validators needed | 50 active | Each handles 3-5 concurrent stakes |
| Runway to profitability | ~$280K | 18-month path, fundable |

---

## What's Been Built vs. What's Next

### ✅ Complete (Phase 0)
- Validator simulation UI
- Economics analysis
- Architecture design
- BoraStaking.sol contract
- 17 comprehensive tests

### 🚧 In Progress (Phase 1)
- BoraMarketplace.sol (listings, sales)
- BoraDispute.sol (3-tier arbitration)
- InsurancePool.sol (shared coverage)
- Integration tests

### 📋 Planned (Phase 2+)
- Agent API (Node.js + Express)
- Real wallet integration (wagmi + Base L2)
- Testnet deployment
- Founding validator program
- Mainnet launch

---

## Common Questions

**Q: Is this actually deployed on-chain?**
A: Not yet. Phase 0 is pure simulation. Phase 1 contracts are written but not deployed. Testnet deployment comes after audit.

**Q: Can I use this code?**
A: Yes, MIT licensed. Fork it, adapt it, ship it.

**Q: Why Base L2 instead of Ethereum mainnet?**
A: Gas costs. Ethereum would make every stake transaction $10-50 in fees. Base L2 keeps it under $0.50.

**Q: What if the insurance pool runs out?**
A: Validators bear 60% of losses directly. The pool only covers 40%. At >5% dispute rate, pool depletes and validators absorb full risk (incentivizing accuracy).

**Q: Why not just use traditional escrow?**
A: Escrow requires human intermediaries and takes days. Smart contracts enforce rules automatically and settle instantly on-chain.

---

## Next Actions

1. **Test the simulation**: Does the APY math check out?
2. **Review the contracts**: Any security concerns?
3. **Read economics doc**: Agree with the incentive model?
4. **Challenge assumptions**: Where are the weak points?

If all three check out, we proceed to:
- Write remaining contracts (Marketplace, Dispute, Insurance)
- Full integration testing
- External audit
- Testnet deployment

---

Built by @iammcqwory • Bora International Group
