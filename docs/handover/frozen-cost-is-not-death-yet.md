---
workstream: frozen-cost-is-not-death-yet
status: in-progress
branch: claude/frozen-cost-is-not-death-yet
pr: none
plan: frozen-cost-is-not-death-yet
issue: none
session: https://claude.ai/code/session_01GYdGcmwBnhagB59b3g1UXa
agent: opus
updated: 2026-10-10
next: Run ci and verify, verifier review, retire, PR, merge
---

## Goal

Settle `docs/research/frozen-cost-is-not-death-yet.md`: may the health table
read a frozen `cost_usd` as death, and after what floor. Graduate to
`.claude/commands/orchestrate.md` step 2, delete the research file.

## Decisions

- Settled NO, no floor: live silence on cost has no ceiling (RUNNING with
  no cost, IDLE gaps, suspension). A live RUNNING manager read with no cost for 117 minutes.
- Graduation = one entry in orchestrate.md step 2 "decide nothing" list, the
  why in orchestrated.md beside push age. No new table row.

## Rejected

- "Cost is a turn-end write" as the why: refuted by cost moving between
  RUNNING reads (r1).
- A RUNNING-only floor: the 117-minute first turn with no cost refutes it;
  no knob bounds a turn's length.

## Review

- r1: (verifier) "turn-end write" overstated: RUNNING rows moved cost a minute apart, and `5f5cc37` records a mid-turn rise. (fixed: mechanism marked UNGROUNDED; verdict rests on the 117-minute live RUNNING read, IDLE gaps and suspension)
- r2: (verifier) contradicting readings and the second CRM-manager read missing from the record. (fixed: all reads listed in Method and Findings)
- r3: (verifier) "STRONG" is not a README word; Verification named no checker. (fixed: GROUNDED/WEAK/UNGROUNDED; Verification opens with what the reviewer re-sampled)
- r4: (verifier) hand-written date as provenance. (fixed: removed from both files)
- r5: (verifier) settle criterion replaced without saying so. (fixed: Verification says it was replaced and why)
- r6: (verifier) Graduates-to named the evidence table; diff also writes orchestrated.md. (fixed: names the decide-nothing list and the why file, as the push-age node did)
- r7: (verifier) bare `usage.cost_usd`, parenthetical only covered RUNNING. (fixed: full path, running/idle/suspended)
- r8: (verifier) research file not yet deleted. (fixed: retire commit)
- r9: (verifier) Method "below" ambiguous after the edit. (fixed: rewritten)

## Blockers

None.

## Where to look

- `docs/research/frozen-cost-is-not-death-yet.md` — the item.
- `.claude/commands/orchestrate.md` step 2 — graduation target.
- `.agents/docs/orchestrated.md` — push-age and knob-table precedent.
