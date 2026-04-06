# Bora Agent Market - Validator Simulation (Phase 0)

> Testing the economics before touching smart contracts.

## What This Is

A React app that simulates the validator staking mechanics of Bora Agent Market. No blockchain required yet — just testing if the incentive model works.

## The Test

**Question**: Will validators stake capital to verify items if they earn 1.0% commission?

**Answer**: This simulator lets you find out by tracking APY in real-time.

## Features

- ✅ Mock listings feed (8 pre-loved gear items)
- ✅ Stake/unstake simulation (locks virtual USDC)
- ✅ Live APY calculation dashboard
- ✅ Dispute resolution simulator (test slashing mechanics)
- ✅ Toast notifications for user feedback
- ✅ "Nairobi Tech" aesthetic (dark mode, green/gold accents, glassmorphism)

## Setup

```bash
npm install
npm run dev
```

Open http://localhost:5173

## How to Use

1. **Connect Wallet** (simulated — just sets a mock address)
2. **Browse listings** in the feed
3. **Click "Stake"** on any item to lock virtual USDC
4. **Watch your dashboard** update with total staked, commissions earned, and APY
5. **Test disputes** using the Dispute Simulator
   - Select a staked item
   - Choose outcome (Buyer Wins = stake slashed, Validator Wins = keep stake)
   - See how slashing affects your APY

## The Economics Being Tested

From `/docs/economics-analysis.md`:

- **Target APY**: 25-40% to justify the risk
- **Commission**: 1.0% of sale price
- **Stake required**: 20-75% of item value (tiered)
- **Dispute rate assumption**: 5% (1 in 20 verifications goes wrong)

**Key insight**: At 50% stake and 1.0% commission, validators earn ~39% APY with 95% accuracy. That beats DeFi lending (5-8% APY) and justifies the slashing risk.

## What Gets Built Next

This simulation proves the validator incentive model works. Next steps:

1. **Phase 1**: Write Solidity contracts for real USDC staking on Base L2
2. **Phase 2**: Build the Agent API for autonomous bidding
3. **Phase 3**: Launch full marketplace with real validators

## Tech Stack

- React + Vite + TypeScript
- Tailwind CSS (custom Bora theme)
- No blockchain yet (Phase 0 is pure simulation)

## File Structure

```
validator-sim/
├── src/
│   ├── components/
│   │   ├── ListingCard.tsx        # Item card with stake UI
│   │   ├── ValidatorDashboard.tsx # APY tracking panel
│   │   ├── DisputeSimulator.tsx   # Test slashing mechanics
│   │   └── ToastNotification.tsx  # User feedback
│   ├── data/
│   │   └── mockListings.ts        # 8 sample items
│   ├── App.tsx                    # Main app
│   └── index.css                  # Tailwind + custom utilities
└── README.md (this file)
```

## Why Simulator-First?

**Traditional approach**: Write smart contracts, deploy to testnet, realize economics are broken, rewrite everything.

**Our approach**: Simulate the economics in a weekend, get the incentive model right, THEN write contracts.

This saves weeks of trial-and-error on-chain.

---

Built by @iammcqwory • Part of Bora International Group
