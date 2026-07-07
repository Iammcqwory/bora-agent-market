# Bora Agent Market - Roadmap

> Prioritized backlog of suggested updates. Derived from `PROJECT_STATUS.md`,
> `QUICKSTART.md`, and hands-on testing of the `validator-sim` prototype.
> Last updated: July 6, 2026.

Legend: **P0** = critical path / blocking, **P1** = high value, **P2** = important but not urgent.
Status: `todo` | `in-progress` | `done` | `blocked`

---

## Critical Path (next iteration)

### 1. Build the backend agent API — P0 — `todo`
The `backend/` directory is an empty scaffold. Build the first real service with the
endpoints called out in the docs:
- Agent identity + auth
- Listing reads
- Validation bids
- Dispute evidence submission
- Trust signals

*Why it matters:* single biggest gap; blocks live frontend integration and real agent flows.

### 2. Wire the frontend to live wallet / on-chain data — P0 — `todo`
`validator-sim` is entirely mock today (mock wallet, mock listings, simulated USDC).
- Add real wallet connection (wagmi/viem)
- Replace mock listing feed with contract reads
- Replace simulated stake/dispute with real transactions

*Depends on:* #3 (deployed contracts).

### 3. Deploy contracts to Base Sepolia testnet — P0 — `blocked`
Deployment scripts exist but are pre-deployment.
- Deploy `BoraStaking`, `BoraMarketplace`, `BoraDispute`, `InsurancePool`
- Verify on Basescan
- Wire addresses into frontend config

*Sequencing:* do only after hardening (#4) and internal review. *Blocked on:* deploy keys/funds + audit sign-off.

### 4. Expand contract hardening tests — P0 — `in-progress`
- [x] Added `contracts/test/InsurancePool.t.sol` (11 unit tests: premium calc,
      40% coverage, partial payout on depletion, empty-pool zero payout, access
      control, seeding, pool health, emergency withdraw). **Unverified locally —
      Foundry (`forge`) is not installed on this machine; run `forge test` in CI
      or locally before merge.**
- [ ] Add dedicated `BoraDispute.t.sol` (also only covered via `Integration.t.sol`)
- [ ] Add fuzz/invariant coverage for the InsurancePool emergency-premium path
      (rate rises to 3% once balance drops below 20% of target)
- [ ] Add marketplace payout-conservation edge cases

---

## Quick Wins (UX / DX)

### 5. Fix blank-frame-on-first-load — P1 — `done`
- [x] Added an instant inline loading placeholder (spinner + "Loading Bora Agent
      Market…") inside `#root` in `index.html`. It paints before the JS bundle
      runs and React replaces it on mount. Verified in-browser: no leftover
      spinner, app mounts cleanly. Ships in the production build too.

### 6. Improve validator onboarding flow — P1 — `done`
- [x] Made the Step 1/2/3 cards dynamic — each shows a live status badge
      (`Do this next` / `✓ Done` / `Upcoming`) with gold/green highlighting driven
      by real state. Step 2 ("Stake") correctly keys off the user's *own* stake
      (`validator === 'YOU'`), not the pre-staked mock listings. Verified the full
      connect -> stake progression in-browser.
- [ ] Follow-up: extend the same live guidance to the dispute step outcomes.

### 9. Address the Vite startup warning — P2 — `investigated / no-fix-needed`
Root cause: the ~46s was a **one-time cold dependency pre-bundle** (Vite 8 /
rolldown re-optimizing because the cache was empty). Warm `npm run dev` starts in
~2.3s and `npm run build` in ~1.6s. The `PLUGIN_TIMINGS` / `externalize-deps`
message is an internal diagnostic during that one-time optimize, not a recurring
problem — no config change warranted. If cold starts become a pain point,
pre-warm with `vite optimize` in CI/container setup.

---

## Reliability & Trust

### 7. Verify CI is green — P1 — `in-progress`
- [x] **Fixed a real gap:** `frontend.yml` ran build + lint but never ran the
      test suite. Added a `npm test` step so the 4 unit tests run in CI.
- [ ] **Verify `slither.yml` config:** it passes inline JSON to the action's
      `slither-config:` input, which expects a *path* to a config file, not inline
      content. Likely needs to become a real `slither.config.json` file. Confirm on
      first run.
- [ ] Trigger first real runs of all three workflows (needs a push to the GitHub
      remote — can't be done from this local, non-authenticated environment).

### 8. External security audit — P0 — `blocked`
Prerequisite before any mainnet direction. *Blocked on:* audit vendor engagement (external).

### 10. Production dispute operations & reviewer tooling — P2 — `todo`
Needed before real disputes can be resolved off the simulator.
- Reviewer workflow/tooling
- Dispute operations runbook

---

## Suggested Sequencing

1. **Now:** #5, #9 (quick DX/UX wins), #7 (confirm CI), #4 (test hardening)
2. **Next:** #1 (backend API), #6 (onboarding polish)
3. **After hardening + audit:** #2 (live integration), #3 (testnet deploy), #8 (audit), #10 (dispute ops)
