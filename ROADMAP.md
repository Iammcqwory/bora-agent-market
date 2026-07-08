# Bora Agent Market - Roadmap

> Prioritized backlog of work. Derived from `README.md`, `QUICKSTART.md`,
> hands-on testing of the `validator-sim` prototype, and the first green/red
> CI runs.
> Last updated: July 8, 2026.

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
- [x] Added `contracts/test/InsurancePool.t.sol` (11 unit tests). **Verified in
      CI: 11 passed, 0 failed** once the suite could compile.
- [ ] Add dedicated `BoraDispute.t.sol` (also only covered via `Integration.t.sol`)
- [ ] Add fuzz/invariant coverage for the InsurancePool emergency-premium path
      (rate rises to 3% once balance drops below 20% of target)
- [ ] Add marketplace payout-conservation edge cases

### 4b. Fix failing BoraMarketplace tests — P0 — `todo`
Surfaced once CI could compile the contracts for the first time. Both are real
logic/expectation bugs, not config issues:
- [ ] `test_CompleteSale_Success` — escrow payout is off by exactly $105
      (`100000900000` vs `99895900000`). Decide whether the fee/escrow math or the
      test's expected value is wrong.
- [ ] `testFuzz_CompleteSaleDistributesEscrowExactly` — fuzzer found `price = 3`
      reverts with `InvalidAmount()` (tiny-price edge case; commission likely
      rounds to 0 or trips a minimum check).

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

### 7. Get CI green — P1 — `in-progress`
- [x] **Frontend workflow: green.** Added the missing `npm test` step, then fixed
      a stale `package-lock.json` (internal `@emnapi` version inconsistency) that
      broke `npm ci`. Regenerated the lockfile; `npm ci` + build + lint + tests all
      pass in CI.
- [x] **Contracts workflow: now compiles + runs.** Fixed `foundry.toml` (a
      misplaced `gas_reports` key broke `forge config`), added `remappings.txt`,
      installed pinned deps (`forge-std@v1.9.4`, `openzeppelin-contracts@v5.1.0`),
      and renamed the `StakeLocked` event (it collided with the `StakeLocked`
      error and blocked compilation). Most tests pass; see #4b for the remaining
      failures.
- [x] **Slither workflow: now runs.** Replaced the Docker action (which had no
      `forge` to compile the project) with a job that installs Foundry + deps and
      runs `slither . --fail-high`. It now analyzes successfully — see #8b for the
      finding it flags.

### 7b. Vercel deployment config — P1 — `todo`
The app lives in `validator-sim/`, not the repo root, so Vercel's default build
finds no `package.json`. Set the project's **Root Directory** to `validator-sim`
in the Vercel dashboard (Settings → Build & Deployment), then redeploy. The
frontend build itself is green.

### 8. External security audit — P0 — `blocked`
Prerequisite before any mainnet direction. *Blocked on:* audit vendor engagement (external).

### 8b. Triage Slither's high-severity finding — P1 — `todo`
Slither flags `arbitrary-send-erc20` in `BoraStaking.lockStake`
(`USDC.transferFrom(validator, …)` uses a non-`msg.sender` `from`). In context
this is by design — the marketplace pulls a validator's pre-approved USDC — but
it's a security decision: either refactor the flow or explicitly annotate/accept
the finding. Do not silence it without a decision.

### 10. Production dispute operations & reviewer tooling — P2 — `todo`
Needed before real disputes can be resolved off the simulator.
- Reviewer workflow/tooling
- Dispute operations runbook

### 11. Homepage + About redesign — P1 — `done`
- [x] New minimalist terminal-style home (typed boot lines, blinking cursor).
- [x] Moved all copy to a terminal-themed About page with a Dynamic Island-style
      morphing pill nav (collapses to the active section, expands on hover) and a
      giant background section word.
- [x] Applied the terminal-green theme site-wide (header, simulator, dashboard,
      listings, disputes).

---

## Suggested Sequencing

1. **Now:** #4b (fix marketplace tests), #8b (triage Slither finding), #7b (Vercel root dir)
2. **Next:** #1 (backend API), #4 (more test hardening)
3. **After hardening + audit:** #2 (live integration), #3 (testnet deploy), #8 (audit), #10 (dispute ops)
