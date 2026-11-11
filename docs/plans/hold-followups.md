---
plan: hold-followups
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/dispatch-park.sh, .agents/docs/orchestrated.md, .agents/scripts/c2-run.sh, .agents/harness/selftest/c2-run.sh
---

## Goal

Close the four findings reported on PR #734 (red-base HOLD until the fix
retires), as the requester asked ("fix all four"):

1. A park whose fix already retired after its block (`dplan` set) still
   counted toward the hold when a second plan naming #<n> was live, so a
   green base stayed held until that second plan merged.
2. A fix row that is itself WAIT or overlap-HOLD lost the red-base context:
   no line said the red base waits on it.
3. No selftest pins for a claimed fix, a fix behind an open `needs:`, a
   CORE ONLY fix, research and requirement rows under the hold.
4. `c2-run: no worktree outlives a run` failed once (2 worktrees): the
   runner's cleanup drops every `worktree remove` error, never re-checks,
   and one `--force` refuses a worktree still locked by an interrupted add.
   Root cause, found building it: runs share one repo, and `worktree add` /
   `remove` die on another run's half-written admin entry (`failed to read
   .git/worktrees/pre1/commondir`): a failed remove leaks a worktree, a
   failed add loses a verdict (`helperchar`, seen 2026-11-11).

## Scope

- `joharness.sh` (cmd_dispatch) — 1: a park counts toward the hold only
  while its fix has not retired (`dplan` = `-`). 2: a fix row held by WAIT or
  an overlap prints one summary line naming it and the red base.
- `.agents/harness/selftest/dispatch-park.sh` — pins for 1, 2, 3.
- `.agents/docs/orchestrated.md` — The one stop: the second-plan sentence
  now says a retired fix lifts the hold; the held-fix line.
- `.agents/scripts/c2-run.sh` — `worktree add` retried on a lost race;
  cleanup: remove retried with `--force --force`, then drop the
  run's own admin entry under `.git/worktrees/` if git still lists it; never
  `worktree prune` (other runs share the repo).
- `.agents/harness/selftest/c2-run.sh` — one run whose git shim fails every
  `worktree remove`: still no worktree left; one whose first `worktree add`
  fails: the verdict stands.

## Assumptions

- A1: `DEFECT_STATE` column 3 is the retired fix stem or `-` for PARKED and
  STUCK — evidence: `joharness.sh:dispatch_defect_state` — confidence: high.
- A2: `git worktree list` lists a worktree while `.git/worktrees/<id>/gitdir`
  exists, dir gone or not — evidence: git-worktree(1) — confidence: high.

## Out of scope

- The clerk's due logic. Unchanged.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.
- `grep -c "a retired fix lifts the hold" .agents/harness/selftest/dispatch-park.sh` — `1` (today `0`).
- `grep -c "remove fails" .agents/harness/selftest/c2-run.sh` — at least `1` (today `0`).
- SHIPS: dispatch, c2-run and their selftests reach every consumer on sync.

## Where to look

- `joharness.sh:cmd_dispatch` — `dpark`, the free-row walk, summary lines.
- `.agents/scripts/c2-run.sh:c2_cleanup`.

## Traps

- Never skip or weaken a selftest pin to get green.
