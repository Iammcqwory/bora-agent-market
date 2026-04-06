# Bora Agent Market - Deployment Checklist

> Complete this checklist before deploying to testnet or mainnet

---

## Phase 1: Contract Completion ✅

- [x] BoraStaking.sol written
- [x] BoraMarketplace.sol written
- [x] BoraDispute.sol written
- [x] InsurancePool.sol written
- [x] Unit tests (40+ tests)
- [x] Integration tests (full flows)
- [x] Gas optimization (<150k per operation)

---

## Phase 2: Internal Review (Current Phase)

### Code Quality
- [ ] All compiler warnings resolved
- [ ] No hardcoded addresses (except constants)
- [ ] Events emitted for all state changes
- [ ] Error messages are descriptive
- [ ] NatSpec comments complete

### Security Review
- [ ] Reentrancy guards on all external calls
- [ ] Access control checked (onlyOwner, onlyMarketplace, etc.)
- [ ] Integer overflow/underflow impossible (Solidity 0.8.23)
- [ ] No delegatecall vulnerabilities
- [ ] Pausability tested
- [ ] Emergency withdrawal paths secure

### Test Coverage
- [ ] Run `forge coverage` → target 95%+
- [ ] All edge cases covered
- [ ] Fuzz testing added for critical functions
- [ ] Integration tests pass
- [ ] Gas benchmarks documented

### Documentation
- [ ] README complete
- [ ] Architecture diagram updated
- [ ] Deployment instructions written
- [ ] User guide drafted
- [ ] Developer documentation complete

---

## Phase 3: Testnet Deployment (Base Sepolia)

### Pre-Deployment
- [ ] Foundry installed and updated
- [ ] Base Sepolia RPC configured
- [ ] Deployer wallet funded (0.01 ETH for gas)
- [ ] USDC mock token deployed (or use existing)
- [ ] Basescan API key obtained

### Deployment Sequence
1. [ ] Deploy InsurancePool
2. [ ] Deploy BoraStaking (with pool address)
3. [ ] Deploy BoraMarketplace (with staking address)
4. [ ] Deploy BoraDispute (with marketplace address)
5. [ ] Connect contracts (set authorized addresses)
6. [ ] Verify on Basescan

### Post-Deployment Testing
- [ ] Create 10 test listings
- [ ] 5 validators stake on items
- [ ] 5 successful purchases
- [ ] 2 dispute resolutions (1 buyer wins, 1 validator wins)
- [ ] Insurance pool receives premiums
- [ ] All events emitted correctly
- [ ] Gas costs match benchmarks

### Stress Testing
- [ ] 100 transactions in 24 hours
- [ ] 10 concurrent stakes
- [ ] 5 simultaneous disputes
- [ ] Pool depletion scenario
- [ ] Contract pause/unpause
- [ ] Monitor for unexpected behavior

---

## Phase 4: External Audit

### Audit Firm Selection
**Options**:
- Trail of Bits ($25-30K, 3-4 weeks)
- OpenZeppelin ($15-20K, 2-3 weeks)
- Consensys Diligence ($20-25K, 3 weeks)
- Code4rena (Public contest, $10-15K prize pool)

**Recommendation**: OpenZeppelin (good balance of cost/quality)

### Audit Preparation
- [ ] Freeze contract code (git tag)
- [ ] Provide comprehensive docs
- [ ] Share test suite
- [ ] Explain economic model
- [ ] List known limitations
- [ ] Define threat model

### During Audit
- [ ] Daily communication with auditors
- [ ] Answer questions promptly
- [ ] Document all findings
- [ ] Prioritize critical issues

### Post-Audit
- [ ] Fix all critical and high issues
- [ ] Consider medium issues (case-by-case)
- [ ] Re-test after fixes
- [ ] Publish audit report
- [ ] Update documentation

---

## Phase 5: Mainnet Preparation

### Smart Contract Finalization
- [ ] All audit issues resolved
- [ ] Final gas optimization pass
- [ ] Remove all console.log statements
- [ ] Final security review

### Infrastructure Setup
- [ ] Base mainnet RPC (Alchemy/Infura)
- [ ] Multi-sig wallet for owner (Gnosis Safe)
- [ ] Treasury wallet created
- [ ] Insurance pool seeded ($20K USDC)
- [ ] Monitoring alerts configured

### Legal & Compliance
- [ ] Terms of Service drafted
- [ ] Privacy policy written
- [ ] Disclaimer added to UI
- [ ] Regulatory review (if needed)

### Community Preparation
- [ ] Founding Validator program launched
- [ ] Documentation published
- [ ] Tutorial videos created
- [ ] Support channels opened (Discord/Telegram)

---

## Phase 6: Mainnet Deployment

### Pre-Launch
- [ ] Final audit report reviewed
- [ ] Team briefing complete
- [ ] Rollback plan documented
- [ ] Insurance pool funded
- [ ] Monitoring dashboard live

### Deployment Day
- [ ] Deploy during low-activity hours (weekend)
- [ ] Use multi-sig for all owner functions
- [ ] Verify contracts on Basescan
- [ ] Test basic flows immediately
- [ ] Monitor for 24 hours

### Soft Launch (Week 1)
- [ ] Whitelist 10 founding validators
- [ ] Cap TVL at $50K
- [ ] Max 50 listings active
- [ ] Daily monitoring
- [ ] Bug bounty live

### Scale-Up (Weeks 2-4)
- [ ] Remove validator whitelist
- [ ] Increase TVL cap to $200K
- [ ] Allow 200 concurrent listings
- [ ] Marketing campaign begins
- [ ] Weekly performance reviews

### Full Launch (Month 2+)
- [ ] Remove all caps
- [ ] Open validator applications
- [ ] Launch partnerships
- [ ] Target break-even GMV ($880K/month)

---

## Audit Preparation Checklist

### Code Documentation
- [ ] NatSpec comments on all public functions
- [ ] README with architecture overview
- [ ] Threat model documented
- [ ] Known limitations listed

### Test Suite
- [ ] Unit tests (95%+ coverage)
- [ ] Integration tests
- [ ] Fuzzing tests
- [ ] Invariant tests
- [ ] Gas benchmarks

### Threat Analysis
- [ ] Reentrancy attack vectors
- [ ] Access control bypass scenarios
- [ ] Economic manipulation attacks
- [ ] Front-running risks
- [ ] Oracle manipulation (dispute tier 1)
- [ ] Griefing attacks

### Economic Model Documentation
- [ ] Commission structure explained
- [ ] Stake tier calculations
- [ ] Insurance pool mechanics
- [ ] Break-even analysis
- [ ] Attack cost modeling

---

## Risk Assessment

### Critical Risks (Must Fix Before Mainnet)
- [ ] Smart contract exploit (funds stolen)
- [ ] Oracle manipulation (AI tier disputes)
- [ ] Insurance pool insolvency
- [ ] Access control bypass

### High Risks (Must Address Before Scale)
- [ ] Economic attack (wash trading)
- [ ] Validator collusion
- [ ] Front-running MEV
- [ ] Gas price manipulation

### Medium Risks (Monitor & Mitigate)
- [ ] Validator recruitment failure
- [ ] Dispute rate >5% (pool depletes)
- [ ] User adoption slower than expected
- [ ] Competitor launch

### Low Risks (Accept & Document)
- [ ] Base L2 downtime
- [ ] USDC depeg
- [ ] Regulatory changes
- [ ] Market conditions

---

## Success Metrics

### Technical
- All tests passing ✅
- Gas costs <150k per operation ✅
- Zero critical audit findings ⏳
- 99.9% uptime ⏳

### Economic
- 50 active validators ⏳
- $880K monthly GMV ⏳
- LTV:CAC > 3× ⏳
- Dispute rate < 5% ⏳

### Product
- 500 active listings ⏳
- 1,000 completed sales ⏳
- NPS > 50 ⏳
- <1% fraud rate ⏳

---

## Current Status

✅ **Phase 1 Complete**: All contracts written, tested, documented  
⏳ **Phase 2 In Progress**: Internal review, prepare for audit  
📋 **Phase 3 Pending**: Testnet deployment  
📋 **Phase 4 Pending**: External audit  
📋 **Phase 5 Pending**: Mainnet preparation  
📋 **Phase 6 Pending**: Mainnet deployment

**Next Action**: Complete internal security review, then deploy to Base Sepolia.

---

Built by @iammcqwory • Bora International Group
