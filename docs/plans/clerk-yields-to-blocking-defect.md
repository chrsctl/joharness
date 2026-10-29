---
plan: clerk-yields-to-blocking-defect
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .claude/commands/clerk.md, .claude/commands/orchestrator.md, .agents/docs/orchestrated.md, .agents/docs/orchestrator-reference.md, .agents/harness/selftest/dispatch-park.sh
---

## Goal

A clerk whose own pull request is held by the same red a parked manager
waits on holds the clerk cycle for `JOHARNESS_CLERK_STALE_HOURS` (24h), so
the early clerk `JOHARNESS_DEFECT_CLERK_HOURS` calls never comes. chrsctl/gx,
2026-10-29: clerk PR #1100 ended "merge blocked by finish check", defect
#1101 filed `blocking:` 43 minutes later, no clerk ran for about five hours.
A park-called clerk must not wait on an in-flight clerk that cannot merge.

## Scope

- `joharness.sh` — dispatch's clerk block (`clerk : IN FLIGHT, so none is
  due`) and `cmd_clerk`: when `clerk_park_early` sets `CLERK_EARLY` and the
  in-flight clerk has pushed nothing since that first park (its tip predates
  it, the park now `JOHARNESS_DEFECT_CLERK_HOURS` old: a clerk that cannot
  merge, not one still working), print the clerk DUE row anyway (one more
  clerk, still at most two).
- `.claude/commands/clerk.md` §1 — the twin check lets the park-called clerk
  through.
- `.agents/docs/orchestrated.md` — the knob table row and the cadence-gap
  paragraph.
- A selftest case: in-flight clerk older than a park, no plan names the
  issue, past `JOHARNESS_DEFECT_CLERK_HOURS` = DUE.

## Assumptions

- A1: an in-flight clerk suppresses the early due — evidence:
  `joharness.sh:cmd_dispatch` prints IN FLIGHT whenever `n_clerk > 0`,
  before reading `kstate` — confidence: high
- A2: gx's timeline (clerk 12:20Z, #1101 13:03Z, none until 17:29Z) — evidence:
  a consumer's session records, not re-taken here — confidence: medium

## Out of scope

- Changing `JOHARNESS_CLERK_STALE_HOURS` or `JOHARNESS_DEFECT_PLAN_HOURS`
  defaults (`joharness.sh` knob table): a fleet-wide default is its own plan.
- Dispatch spawn holds (`dispatch-holds-shared-defect`).

## Acceptance

- The new selftest case — fails with the change reverted, passes with it;
  a second case: an in-flight clerk that pushed after the park = not DUE.
- Consumer-side (SHIPS): `./joharness.sh dispatch` in a consumer checkout
  with that state prints `clerk     : DUE`.
- `./joharness.sh ci` — `ci: pass`
- `./joharness.sh verify` — `0 failed`

## Where to look

- `joharness.sh:clerk_park_early` — the early due.
- `joharness.sh:cmd_dispatch` — where IN FLIGHT wins.
- `.claude/commands/clerk.md:Twin check` — the one-in-flight rule.

## Traps

- Never two park-called clerks: the second waits as today.
