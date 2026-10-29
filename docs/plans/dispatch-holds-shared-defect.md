---
plan: dispatch-holds-shared-defect
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .claude/commands/orchestrator.md, .agents/docs/orchestrated.md
---

## Goal

With five managers parked on one unplanned `blocking:` defect, the gx
orchestrator spawned two more onto the same red base, and both parked on it
within 15 minutes (chrsctl/gx, 2026-10-29 15:45Z, #1101). A red base every
new manager will hit at `finish` should hold new spawns until the defect is
planned or fixed.

## Scope

- `joharness.sh:cmd_dispatch` — when two or more PARKED rows name the same
  issue no plan names, the `spawn` rows read HOLD with that issue, and the
  verdict names it; a plan naming the issue lifts the hold.
- `.claude/commands/orchestrator.md` — the HOLD row's action.
- `.agents/docs/orchestrated.md` — why.
- A selftest case: two parks on #N, no plan = HOLD; a plan with `issue: N` = spawn.

## Assumptions

- A1: dispatch spawns past shared parks today — evidence:
  `joharness.sh:dispatch_defect_state` sets a per-branch state; no spawn
  row reads it — confidence: medium, check before building
- A2: gx's 15:45Z spawns parked by 16:00Z — evidence: a consumer's session
  records, not re-taken here — confidence: medium

## Out of scope

- A fast-lane manager for the defect itself: a clerk plans it
  (`clerk-yields-to-blocking-defect`).
- Lowering `JOHARNESS_DEFECT_PLAN_HOURS` when two or more managers park on
  one issue: the hold already stops the fan-in; the notify window is its
  own plan if the hold proves short.

## Acceptance

- The new selftest case — fails with the change reverted, passes with it.
- Consumer-side (SHIPS): `./joharness.sh dispatch` in a consumer checkout
  with two parks on one unplanned issue prints the HOLD row naming it.
- `./joharness.sh ci` — `ci: pass`
- `./joharness.sh verify` — `0 failed`

## Where to look

- `joharness.sh:dispatch_defect_state` — the park states.
- `joharness.sh:cmd_dispatch` — the spawn rows.

## Traps

- A hold is never a slot: held items stay in the queue.
