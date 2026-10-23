---
plan: defect-recheck
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, .claude/commands/orchestrate.md, .agents/docs/orchestrate-reference.md, shared:.agents/docs/orchestrated.md, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

A manager parked on `defect: #<n>` resumes only when a plan that names #<n>
retires on the base (`RESUME`). When the defect is fixed some other way, for
example a direct pull request that names no plan, the item stays parked.
Nothing resumes it until `UNPLANNED` notifies the human at
`JOHARNESS_DEFECT_PLAN_HOURS` (48h). The human is not needed for that: the
fleet can check whether the defect is still there. Add a state that lets
the parked manager re-check once the base has moved, so that a fixed defect
resumes within hours, not days, and with no human.

## Scope

- `joharness.sh:dispatch_defect_state`: add the state `RECHECK`. It holds
  when there is no `RESUME`, no plan on the base or on a live branch names
  #<n>, at least `JOHARNESS_DEFECT_RECHECK_HOURS` have passed since the
  block commit, and the base's first parent has a commit after the block
  commit. It ranks after `RESUME`, `STUCK` and `UNPLANNED` (first-park
clock), and a RESUME row takes a slot before it. It
  prints `PARKED #<n> RECHECK` on the dispatch row and under the verdict,
  in the same way `RESUME`'s row is printed.
- `joharness.sh` knob table: `JOHARNESS_DEFECT_RECHECK_HOURS`, default 2,
  scope dispatch; 0 lifts it.
- `.claude/commands/orchestrate.md` health table: a row for `PARKED #<n>
  RECHECK`, handled the way the `RESUME` row is, in step 3 as one of this
  pass's spawns.
- `.agents/docs/orchestrate-reference.md` § Resume: the RECHECK `next:`
  wording is `Recheck: the base moved since you parked on #<n>; merge
  origin/main, re-run the check that failed; still red = park again on
  #<n>, green = continue`. RECHECK counts against `JOHARNESS_RESPAWN_LIMIT`
  only when a session has to be respawned, as RESUME does.
- `.agents/docs/orchestrated.md`: add the knob row next to
  `JOHARNESS_DEFECT_PLAN_HOURS` and one sentence where `PARKED` is
  explained.
- `.agents/harness/selftest/dispatch.sh`: add the cases listed under
  Acceptance.

A re-park writes a new block commit, so the RECHECK clock restarts: once
per base advance after the wait, no marker. The orchestrator's commit
writing the `Recheck:` `next:` is what breaks the run (A1). `STUCK` and
`UNPLANNED` measure from the FIRST park on #<n> on the branch, not the
latest block commit: else every re-park resets them and a never-fixed
defect on a moving base never reaches the human.

## Assumptions

- A1: re-parking writes a new `next:` commit that `dispatch_defect_state`
  reads as the new block commit, so RECHECK cannot loop on one base state.
  Evidence: `joharness.sh:dispatch_defect_state`, the "unbroken run" walk.
  Confidence: medium. The same `next:` text written again may not start a
  new run; check this and record it.
- A2: the base's first parent "has a commit after the block commit" can be
  read with `git log -1 --first-parent --since` or a `%ct` compare on
  `origin/main` alone. Evidence: the same function already walks
  `origin/main ^<block commit>`. Confidence: high.

## Out of scope

- Reading issue state on GitHub. Dispatch reads git only.
- Changing `RESUME`, `STUCK` or `UNPLANNED`, apart from ranking RECHECK
  among them and measuring `STUCK` and `UNPLANNED` from the first park on
  #<n>.
- The clerk's cadence.

## Acceptance

- `./joharness.sh ci` gives `ci: pass`, and the selftest has these
  dispatch cases:
  - a parked branch, with the base moved after the block and the block
    older than the knob, prints `PARKED #<n> RECHECK`;
  - the same branch with the base unmoved prints plain `PARKED`;
  - the same branch with the block younger than the knob prints `PARKED`;
  - a plan naming #<n> on the base prints `PARKED`, not RECHECK;
  - `JOHARNESS_DEFECT_RECHECK_HOURS=0` never prints RECHECK;
  - a re-park commit after a RECHECK resets the clock (A1);
  - after re-parks, `UNPLANNED` still fires from the first park.
  Each case that expects `RECHECK` or the first-park clock must FAIL on
  `origin/main`; the `PARKED`-only cases are guards and pass there.
- `./joharness.sh verify` gives `0 failed`.
- `./joharness.sh conf` lists `JOHARNESS_DEFECT_RECHECK_HOURS` with its
  default of 2.

## Where to look

- `joharness.sh:dispatch_defect_state`: the state reader.
- `joharness.sh:cmd_dispatch`: the `RESUME)` and `UNPLANNED)` cases that
  print the rows.
- `.claude/commands/orchestrate.md`: the health table `PARKED` rows.
- `.agents/docs/orchestrate-reference.md:## Resume`.

## Traps

- NEVER skip, disable or quarantine a test to get green.
- A test for a fix must FAIL without it.
- Dispatch reads git only; harness commands never call the GitHub API.
