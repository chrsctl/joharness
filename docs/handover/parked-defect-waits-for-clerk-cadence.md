---
workstream: parked-defect-waits-for-clerk-cadence
status: in-progress
branch: manage/parked-defect-waits-for-clerk-cadence
pr: none
plan: parked-defect-waits-for-clerk-cadence
issue: none
session: https://claude.ai/code/session_01J1YMK3irWS7ZvwcvxxFNCP
agent: opus
updated: 2026-10-28
next: Verifier, ci, open PR, finish and merge
---

## Goal

Settle whether a manager parked on an unplanned `defect:` issue waits out the
clerk's full cadence, and graduate the answer to `.agents/docs/orchestrated.md`.

## Decisions

- Answer: YES. `joharness.sh:clerk_due` reads cycle_unreadable, the knob, clerk.md,
  clerk_landed, clerk_noop and the clock; dispatch sets `clerk_due=1` in one place
  (`joharness.sh:8326`) from that clock. No park state feeds it. Code reading
  GROUNDED; the gx run's numbers are the consumer's reading, WEAK (one run).
- A cadence gap, not intent: graduated as such to orchestrated.md beside the park
  lifecycle. The fix already exists as plan `defect-park-calls-clerk` (no `research:`
  edge on this file), so no new plan; its scope adds the knob row.

## Rejected

- Recording the 24h wait as intended: a parked manager waits on exactly the plan
  the clerk would write; the wait buys nothing.

## Review

- r1: "freed them" overstates: an extra clerk writes the plan, RESUME needs it retired (verifier) (fixed)
- r2: gx numbers stated as fact without a second context (verifier) (fixed: marked one consumer reading, not re-taken here)
- r3: clerk is not the only path, a hand-filed `issue:` plan is one too (verifier) (fixed)
- r4: "up to JOHARNESS_CLERK_HOURS" understates: batch, clerk PR, fix add time (verifier) (fixed)
- r5: one RECHECK re-park generalised to plural (verifier) (fixed)
- r6: paragraph contradicts code once defect-park-calls-clerk lands; that plan cites the deleted research file (verifier) (fixed: paragraph says the plan rewrites it; plan file is not this item's to edit, lead sent to the orchestrator; research file recoverable from git)
- r7: Review empty, workstream file still in tree (verifier) (no change: process state, retire commit deletes it)

## Blockers

None.

## Where to look

- `joharness.sh` — dispatch clerk-due and PARKED rows.
- `.agents/docs/orchestrated.md` — knob table, parked-on-a-defect lifecycle.
