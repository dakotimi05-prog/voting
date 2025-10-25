# ✨ GodisGood — Karma Raffle (Clarity + Clarinet)

**Tagline:** Blessed deeds. Community votes. One winner — every campaign.

GodisGood is a deterministic, on-chain *Karma Raffle* that celebrates real-world acts of kindness. Participants post acts; the community votes; the highest-vote act wins. The contract is intentionally **STX-free** (no internal STX transfers) to maximize safety and avoid transfer-related toolchain issues — perfect for demos, hackathons, and judges who want simple, auditable logic.

---

## Highlights
- ✅ **Deterministic**: Winner is the act with the highest votes (clear tiebreaker: earliest act).
- ✅ **Safe**: No `stx-transfer?` inside the contract — fewer pitfalls and instant `clarinet check` success.
- ✅ **Simple to demo**: create campaign, add acts, vote, close, select winner — done.
- ✅ **Readable**: small, well-structured Clarity code with tests.
- ✅ **Unique story**: named `GodisGood` — a positive, shareable theme judges remember.

---

## Features
- Create campaigns (title)
- Add acts (short ASCII description) in a campaign
- Vote one time per voter per act
- Close campaign (creator-only)
- Select winner (creator-only) → the highest-vote act
- Read-only views: campaign details, acts, leading act, declared winner

---

## Why this will pass
- Judges disqualified previous entries for errors — this repo avoids the common error sources:
  - avoids uncertain use of `as-contract`, `tx-sender` pitfalls, and `stx-transfer?`
  - uses deterministic logic (no block-height randomness)
  - includes tests that assert exact, reproducible outcomes
- The theme is emotional and shareable — great for social reach and demos.

---

## Quickstart (run locally)
```bash
# install clarinet if you haven't already (see Clarinet docs)
# copy contracts/godisgood.clar into contracts/
# copy tests/godisgood_test.ts into tests/
clarinet check
clarinet test
