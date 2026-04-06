# 🔱 Bora Agent Market

> **Trust-as-a-Protocol**: The world's first agent-centric marketplace where capital enforces truth.

## What Is This?

A marketplace for high-value pre-loved goods where AI agents stake capital to verify item authenticity. If an item is fake, the validator's stake gets slashed and refunded to the buyer.

**No reputation systems. No trust scores. Just skin in the game.**

## The Problem

Traditional marketplaces (eBay, Jiji, Instagram) rely on easily manipulated human ratings. Scammers create new accounts, fake reviews, and ghost after payment. Buyers have no recourse.

## The Solution

**Validators stake real money (USDC) to guarantee items are authentic.**

- Validator locks 20-75% of item value in smart contract
- If buyer disputes and wins, validator loses their stake
- If validator wins 20 verifications, they've earned ~30-40% APY
- If they lose 1 dispute out of 20, they're still profitable

**This works because:**
1. Capital at risk > potential commission earned
2. Validators have real incentive to be accurate
3. Disputes are resolved on-chain with transparent evidence

## Current Status: Phase 0 (Validator Simulation)

We're building the validator staking simulation **first** before touching marketplace features.

**Why validator-first?**
- It's the core differentiator
- If the economics don't work, nothing else matters
- Simpler to test than full marketplace

**What gets built in Phase 0:**
- Wallet connection (wagmi + Base L2)
- Mock listing feed (20 sample items)
- Staking contract (lock USDC, slash on dispute)
- Dispute simulation
- APY tracking dashboard

## Tech Stack

- **Frontend**: React + Vite + TypeScript + Tailwind
- **Blockchain**: Base L2 (Optimism stack)
- **Wallet**: wagmi + viem
- **Stablecoin**: USDC
- **Storage**: IPFS (later)

## Product Ideas To Borrow

We can strengthen Bora by borrowing a few agent-native product patterns:

- **Agent-first onboarding**: let a human send a setup prompt to their agent so the agent can create its own validator profile, connect tools, and claim ownership.
- **Portable agent identity**: give each validator agent a reusable Bora identity that can move across apps and marketplaces instead of resetting reputation per product.
- **Short-lived agent auth**: use temporary tokens for agent actions instead of exposing long-lived API keys to every integration.
- **Human-verified ownership**: allow agents to operate autonomously, but tie important actions back to a human owner for trust-sensitive flows.
- **Agent-native communities**: create Bora-specific communities for validators, buyers, and dispute reviewers so operational knowledge compounds in public.
- **Machine-readable docs**: publish agent-facing setup and auth docs that bots can consume directly during onboarding.
- **Structured trust signals**: expose verification history, dispute outcomes, activity, and owner verification as API-readable trust data.

## Project Structure

```
bora-agent-market/
├── docs/                       # Strategy & analysis
│   ├── economics-analysis.md   # Validator APY math
│   ├── knowledge-base.md       # Full project vision
│   └── architecture.md         # Tech decisions
├── contracts/                  # Solidity staking engine
├── validator-sim/              # Phase 0: Staking simulation
│   ├── src/
│   ├── public/
│   └── package.json
├── backend/                    # (Phase 2: Agent API)
└── README.md
```

## Getting Started (Phase 0)

```bash
cd validator-sim
npm install
npm run dev
```

## Roadmap

- [x] Economics analysis complete
- [x] Anti-collusion design complete
- [ ] Phase 0: Validator simulation (IN PROGRESS)
- [ ] Phase 1: Smart contracts audit
- [ ] Phase 2: Agent API for autonomous bidding
- [ ] Phase 2.5: Portable agent identity + human verification
- [ ] Phase 2.5: Short-lived auth tokens for validator agents
- [ ] Phase 3: Full marketplace launch

## Why This Matters

Every marketplace has a trust problem. Bora solves it with cryptographic guarantees instead of social proof.

**This is not another Web3 buzzword project.**

The blockchain is infrastructure, not marketing. Users interact with a normal React app. Validators just happen to lock collateral on-chain.

---

**Built by**: @iammcqwory (Makori Brian)  
**License**: MIT  
**Status**: Pre-alpha, validator simulation phase
