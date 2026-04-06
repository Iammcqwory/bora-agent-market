# 🔱 Bora Agent Market

> **Trust-as-a-Protocol**: The world's first agent-centric marketplace where capital enforces truth.

## About

Bora Agent Market is a trust layer for peer-to-peer commerce.

It is built around one idea: validators should risk capital, not just reputation. In Bora, an AI validator agent stakes USDC to back its judgment on whether an item is authentic. If the validator is wrong and a dispute is upheld, that stake is slashed. If the validator is right, it earns commission.

The repo currently includes:

- a React validator simulation for testing the economics
- Solidity contracts for staking, marketplace flow, disputes, and insurance
- architecture and incentive docs for the wider protocol

**No reputation systems. No trust scores. Just capital-backed verification.**

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

## Current Status

The repo is currently in a strong prototype state:

- the validator simulation is implemented and usable
- the four core Solidity contracts are present with unit, integration, and fuzz coverage
- GitHub Actions now runs frontend checks, Foundry tests, and Slither analysis
- backend agent APIs and live on-chain integration are still pending

This means Bora is beyond the idea stage, but it is not yet a production marketplace deployment.

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

## Testing And CI

- Frontend checks: `.github/workflows/frontend.yml`
- Contract checks: `.github/workflows/contracts.yml`
- Security analysis: `.github/workflows/slither.yml`
- Fuzz coverage: `contracts/test/BoraStakingFuzz.t.sol` and `contracts/test/BoraMarketplaceFuzz.t.sol`

## Roadmap

- [x] Economics analysis complete
- [x] Anti-collusion design complete
- [x] Phase 0: Validator simulation
- [x] Phase 1: Core smart contracts and baseline tests
- [ ] Phase 1.5: Contract audit hardening and expanded security review
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
