# Bora Agent Market: Smart Contract Architecture

> Phase 1: Building the on-chain staking engine

---

## Overview

Phase 0 proved the economics work. Phase 1 makes them real with Solidity contracts on Base L2.

**Core principle**: Keep contracts simple, auditable, and capital-efficient.

---

## Agent Identity Layer

Beyond the contract system, Bora should add an agent identity and trust layer so validator agents can participate across products, not just inside one UI.

### Borrowed Product Patterns

1. **Agent-first onboarding**
   Humans should be able to hand a setup prompt to their validator agent. The agent completes registration, configures permissions, and returns a claim flow to the owner.

2. **Portable agent identity**
   Each validator should have a Bora identity with stable metadata:
   - agent handle
   - owner handle
   - verification status
   - supported domains or categories
   - cumulative validation stats
   - dispute win/loss history

3. **Short-lived authentication**
   Integrations should issue temporary action tokens to agents instead of relying on permanent API keys. This reduces blast radius and makes agent sessions easier to revoke.

4. **Human-verified ownership**
   Validator agents can operate independently, but Bora should support human ownership proofs for high-trust actions such as treasury withdrawals, dispute escalations, and validator registry updates.

5. **Machine-readable onboarding docs**
   Bora should host agent-readable docs for:
   - registration
   - auth
   - allowed actions
   - rate limits
   - trust signal schema

6. **Structured trust signals**
   Trust should not be a vague score. Bora should expose an agent profile API with concrete, inspectable fields such as:
   - total validations
   - active stake
   - average item tier
   - resolved disputes
   - slash count
   - owner-verified boolean
   - last active timestamp

### Proposed Phase 2.5 Components

```text
AgentRegistry
  Stores Bora agent profiles and ownership claims

AgentAuthService
  Issues short-lived auth tokens for approved agent actions

AgentProfile API
  Returns trust signals, validator activity, and verification state

Agent Docs
  Public machine-readable onboarding and integration instructions
```

### Why This Matters

The contract layer enforces capital. The identity layer makes agents usable, discoverable, and composable across the wider agent ecosystem. Together, those two layers make Bora feel like infrastructure instead of a single marketplace app.

---

## Contract Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     BoraMarketplace.sol                      │
│  (Main coordinator - handles listings, sales, commission)   │
└────────┬────────────────────────────────┬───────────────────┘
         │                                │
         ▼                                ▼
┌────────────────────┐          ┌──────────────────────┐
│ BoraStaking.sol    │          │ BoraDispute.sol      │
│ (Lock/release/     │◄─────────┤ (3-tier arbitration) │
│  slash validator   │          │                      │
│  stakes)           │          │                      │
└────────────────────┘          └──────────────────────┘
         │
         ▼
┌────────────────────┐
│ InsurancePool.sol  │
│ (Shared validator  │
│  loss coverage)    │
└────────────────────┘
```

### 1. BoraMarketplace.sol

**Purpose**: Core marketplace logic - listings, purchases, commission distribution.

**Key Functions**:
```solidity
struct Listing {
    uint256 id;
    address seller;
    uint256 price;
    string ipfsHash;        // Item metadata on IPFS
    bool isActive;
    address validator;      // Who staked on this
    uint256 validatorStake;
}

function createListing(uint256 price, string ipfsHash) external returns (uint256)
function stakeListing(uint256 listingId) external
function purchaseListing(uint256 listingId) external payable
function completeSale(uint256 listingId) external
function initiateDispute(uint256 listingId, string evidenceHash) external
```

**Revenue Flow**:
```
Buyer pays $300 USDC
├─> $292.50 (97.5%) → Seller
├─> $3.00 (1.0%) → Validator
└─> $4.50 (1.5%) → Platform treasury
```

**State Transitions**:
```
LISTED → STAKED → PURCHASED → (72hr wait) → COMPLETED
         └─> DISPUTED → RESOLVED → (refund or complete)
```

### 2. BoraStaking.sol

**Purpose**: Manage validator capital locks, slashing, and releases.

**Key Functions**:
```solidity
struct Stake {
    address validator;
    uint256 amount;
    uint256 listingId;
    uint256 lockTimestamp;
    StakeStatus status; // LOCKED, RELEASED, SLASHED
}

function lockStake(uint256 listingId, uint256 amount) external
function releaseStake(uint256 stakeId) external
function slashStake(uint256 stakeId, address beneficiary) external onlyDispute
function getRequiredStake(uint256 itemPrice) public pure returns (uint256)
```

**Tiered Stake Logic**:
```solidity
function getRequiredStake(uint256 itemPrice) public pure returns (uint256) {
    if (itemPrice < 100e6) return (itemPrice * 20) / 100;      // 20%
    if (itemPrice < 500e6) return (itemPrice * 35) / 100;      // 35%
    if (itemPrice < 1000e6) return (itemPrice * 50) / 100;     // 50%
    return (itemPrice * 75) / 100;                              // 75%
}
```

**Security**: 
- Reentrancy guard on all stake operations
- Time-locks prevent instant stake withdrawals
- Only BoraDispute contract can call slashStake

### 3. BoraDispute.sol

**Purpose**: 3-tier arbitration system for fraud claims.

**Tiers**:
1. **AI Auto-Resolve** (0-24hrs): Compare listing photos to buyer evidence using Chainlink Functions
2. **Community Jury** (24-72hrs): 5 high-reputation validators vote
3. **Bora Council** (72hrs+): Human panel for items >$1,000

**Key Functions**:
```solidity
struct Dispute {
    uint256 listingId;
    address buyer;
    string evidenceHash;
    DisputeTier tier;
    uint256 createdAt;
    DisputeStatus status;
    address[] jurors;
    mapping(address => bool) votes; // true = buyer wins
}

function initiateDispute(uint256 listingId, string evidenceHash) external
function submitAIVerdict(uint256 disputeId, bool buyerWins) external onlyOracle
function castJuryVote(uint256 disputeId, bool buyerWins) external
function resolveDispute(uint256 disputeId) external
```

**Resolution Logic**:
```solidity
function resolveDispute(uint256 disputeId) external {
    Dispute storage dispute = disputes[disputeId];
    
    bool buyerWins;
    if (dispute.tier == DisputeTier.AI) {
        buyerWins = dispute.aiVerdict;
    } else if (dispute.tier == DisputeTier.JURY) {
        uint256 buyerVotes = countVotes(dispute.votes, true);
        buyerWins = buyerVotes >= 3; // 3 of 5 majority
    } else {
        buyerWins = dispute.councilDecision;
    }
    
    if (buyerWins) {
        BoraStaking.slashStake(dispute.stakeId, dispute.buyer);
        // Refund buyer, penalize validator
    } else {
        BoraStaking.releaseStake(dispute.stakeId);
        // Release funds to seller, release validator stake
    }
}
```

### 4. InsurancePool.sol

**Purpose**: Shared pool that covers first 40% of validator losses.

**Mechanism**:
```solidity
struct PoolContribution {
    address validator;
    uint256 amount;
    uint256 timestamp;
}

// 2% of stake goes to pool
function contributeToPool(uint256 stakeId, uint256 stakeAmount) external {
    uint256 premium = (stakeAmount * 2) / 100;
    poolBalance += premium;
    contributions[msg.sender].push(PoolContribution({
        validator: msg.sender,
        amount: premium,
        timestamp: block.timestamp
    }));
}

// Pool covers first 40% of slash
function claimInsurance(uint256 slashedAmount, address validator) external onlyStaking returns (uint256) {
    uint256 coverage = (slashedAmount * 40) / 100;
    if (poolBalance >= coverage) {
        poolBalance -= coverage;
        return coverage; // Pool pays this
    }
    return 0; // Pool depleted
}
```

**Pool Economics**:
- At 5% dispute rate, pool breaks even
- If dispute rate < 5%, pool grows
- If dispute rate > 5%, pool depletes (validators bear more risk)

---

## Gas Optimization Strategies

### 1. Batch Operations
```solidity
function stakeMultiple(uint256[] calldata listingIds) external {
    for (uint256 i = 0; i < listingIds.length; i++) {
        _stakeListing(listingIds[i]);
    }
}
```

### 2. Packed Storage
```solidity
struct Listing {
    uint128 price;           // Max $340T (more than enough)
    uint64 id;               // 18 quintillion listings
    uint32 createdAt;        // Timestamp
    address seller;          // 20 bytes
    address validator;       // 20 bytes
    bool isActive;           // 1 byte
    // Total: 3 storage slots instead of 7
}
```

### 3. Use Immutable Constants
```solidity
uint256 public constant COMMISSION_RATE = 100;  // 1.00% (basis points)
uint256 public constant PLATFORM_FEE = 150;     // 1.50%
address public immutable USDC_ADDRESS;
```

---

## Security Considerations

### 1. Reentrancy Protection
```solidity
modifier nonReentrant() {
    require(!locked, "No reentrancy");
    locked = true;
    _;
    locked = false;
}
```

### 2. Access Control
```solidity
// Only BoraDispute can slash stakes
modifier onlyDispute() {
    require(msg.sender == disputeContract, "Unauthorized");
    _;
}

// Only Bora Council can override disputes
modifier onlyCouncil() {
    require(councilMembers[msg.sender], "Not council");
    _;
}
```

### 3. Pausability
```solidity
bool public paused;

modifier whenNotPaused() {
    require(!paused, "Contract paused");
    _;
}

function emergencyPause() external onlyOwner {
    paused = true;
}
```

### 4. Upgrade Path
Use UUPS proxy pattern:
- Logic contracts are upgradeable
- Storage contracts are immutable
- Migration path if critical bug found

---

## Testing Strategy

### Unit Tests (Foundry)
```solidity
contract BoraStakingTest is Test {
    function testStakeRequirement() public {
        // $50 item → 20% stake = $10
        assertEq(staking.getRequiredStake(50e6), 10e6);
        
        // $300 item → 35% stake = $105
        assertEq(staking.getRequiredStake(300e6), 105e6);
    }
    
    function testSlashing() public {
        // Setup: Validator stakes $100 on $300 item
        vm.startPrank(validator);
        staking.lockStake(listingId, 105e6);
        
        // Buyer disputes, validator loses
        vm.startPrank(disputeContract);
        staking.slashStake(stakeId, buyer);
        
        // Verify: Buyer received $105, validator lost $105
        assertEq(usdc.balanceOf(buyer), 105e6);
        assertEq(usdc.balanceOf(validator), 0);
    }
}
```

### Integration Tests
1. Full flow: List → Stake → Purchase → Complete
2. Dispute flow: List → Stake → Purchase → Dispute → Slash
3. Insurance flow: Multiple stakes → One slash → Pool pays 40%

### Mainnet Fork Tests
Run against Base L2 fork:
```bash
forge test --fork-url https://base.llamarpc.com --match-contract Integration
```

---

## Deployment Plan

### Testnet (Base Sepolia)
1. Deploy USDC mock token
2. Deploy contracts in order:
   - InsurancePool
   - BoraStaking (with pool address)
   - BoraDispute (with staking address)
   - BoraMarketplace (with staking + dispute addresses)
3. Fund test validators with mock USDC
4. Run 100 test transactions
5. Trigger 5 disputes, verify slashing

### Mainnet (Base L2)
1. Audit by Trail of Bits or OpenZeppelin
2. Deploy to Base mainnet
3. Seed insurance pool with $5,000 USDC
4. Whitelist first 10 founding validators
5. Gradual rollout: 50 → 100 → 500 listings

---

## Next Steps

1. **Write BoraStaking.sol** (core staking logic)
2. **Write tests** (achieve 95%+ coverage)
3. **Gas optimization** (target <100k gas per stake)
4. **Security review** (internal + external audit)
5. **Deploy to testnet** (Base Sepolia)

---

Built for Bora Agent Market Phase 1
