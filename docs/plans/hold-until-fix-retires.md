---
plan: hold-until-fix-retires
urgency: urgent
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/dispatch-park.sh, .agents/docs/orchestrated.md, .claude/commands/orchestrator.md
---

## Goal

`HOLD — red base: #<n> (<k> parked)` / verdict `DEFECT-BOUND` lifts as soon
as a plan naming #<n> exists on the base or a live branch, but the base stays
red until that plan's fix MERGES. Every manager spawned in between parks
within minutes (chrsctl/gx, 2026-11-10, #1449: four managers spawned
20:42Z–21:48Z, each parked in 5–14 minutes; fix plan on the clerk branch
20:30Z, on main 21:08Z, fix merged 22:22Z). The hold must stand while two or
more parks on #<n> stand and their fix has not retired on the base's first
parent (the RESUME condition), and still let the fix plan itself spawn, with
RESUME and RECHECK rows untouched.

## Scope

- `joharness.sh` (cmd_dispatch) — a park counts toward the hold in states
  PARKED, UNPLANNED, STUCK, RECHECK whether or not a plan names #<n>
  (RESUME, UNREADABLE never count). A free plan row on the base whose
  frontmatter names a held issue is the fix: it spawns, unheld. Row, verdict
  and summary text say "until its fix retires" instead of "no plan names it".
- `.agents/harness/selftest/dispatch-park.sh` — the hold block: a branch plan
  naming #41 keeps the hold; a base plan naming #41 keeps every other row
  held and offers fix41 free; retiring fix41 on the base gives RESUME rows
  and no hold.
- `.agents/docs/orchestrated.md` The one stop, DEFECT-BOUND paragraph — new
  lift condition and the gx 2026-11-10 reading.
- `.claude/commands/orchestrator.md` — the HOLD bullet's lift wording.

## Assumptions

- A1: `dispatch_defect_state` already returns RESUME exactly at retire with no
  plan naming #<n>, and PARKED otherwise for a named issue — evidence:
  `joharness.sh:dispatch_defect_state` — confidence: high.
- A2: `plan_names_issue <rev> <path> <n>` reads a plan's `issue:` — evidence:
  `joharness.sh:plan_names_issue` — confidence: high.

## Out of scope

- Exempting plans the fix plan `needs:` — a fix with an open `needs:` edge is
  already not free; the STUCK notice reaches the human. Said in the doc.
- The clerk's due logic (`clerk_park_early`): unchanged; it already reads
  "named" itself.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.
- `grep -c "a branch plan naming #41 keeps the hold" .agents/harness/selftest/dispatch-park.sh` — `1` (today `0`).
- `grep -c "no plan names it: spawn" joharness.sh` — `0` (today `3`).
- SHIPS: dispatch and its selftest reach every consumer on sync.

## Where to look

- `joharness.sh:cmd_dispatch` — `dpark`, `dhold`, the free-row walk, the verdict.
- `.agents/harness/selftest/dispatch-park.sh` — "two parks on one issue".

## Traps

- Never skip or weaken a selftest pin to get green; replace pins one for one.
