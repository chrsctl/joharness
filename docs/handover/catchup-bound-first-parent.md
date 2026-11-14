---
workstream: catchup-bound-first-parent
status: in-progress
branch: claude/keen-brahmagupta-egur6h
pr: none
plan: catchup-bound-first-parent
issue: none
session: https://claude.ai/code/session_01J1YMK5n638k2v3Vcg17JxV
agent: opus
updated: 2026-11-14
next: verify, finish, retire, open the PR and merge
---

## Goal

Stop green heads looping through full `finish` runs until STARVED on a fast
base (chrsctl/gx #1696). Asked by the owner: "Fix directly in joharness".

## Decisions

- Bound unit = first-parent commits of the base, not all commits: one per
  merged pull request; equals the old count where nothing merges with a
  merge commit. Default 10 (about one gx peak pass plus a retest lap).
- `IN REACH` is a new refusal token, deliberately without the substring
  `OUTRUN`, so a manager's count skips it.
- Plan written and built on one branch: the owner asked for the fix
  directly, and a separate plan pull request would sit in the queue while
  gx keeps starving.

## Rejected

- Counting first-parent merges only: a squash/rebase consumer has none and
  the bound would never bite.

## Review

- r0: (verifier) F0 spawn prompt carried claims and focus beyond the listed fields (no change: the reader re-took every claim itself)
- r1: (verifier) F1 `IN REACH` checked the bound alone; a base changing local-check each move looped full runs never counted (fixed: `checks_in_reach` probes `checks_catch_up` itself on the clean merge; kco3 case red without it)
- r2: (verifier) F2 the base can move past the bound between `IN REACH` and the merge, one uncounted full run (wontfix: seconds against ten pull requests; that full run's own outrun is measured again; documented in consumer-repos.md)
- r3: (verifier) F3 cert base off the ref's first-parent line (fast-forward onto another line) hid the move (fixed: `checks_base_steps` falls back to every commit; scratch repo 14 vs 2)
- r4: (verifier) F4 no test pinned first-parent counting in the reach test (fixed: 2-commit --no-ff pull request case, red with an all-commit count)
- r5: (verifier) F5 stale text: "20 commits", "BEHIND plus OUTRUN", "OUTRUN or NOT OUTRUN" (fixed)
- r6: (verifier) F6 plan not at merge base, no plan-checker (wontfix: the owner asked for the fix directly; the verifier's plan lens covered it)
- r7: (verifier) F7 no case shows an end-of-run outrun still counts under the default bound (fixed: kco3 case is OUTRUN under the default bound)
## Blockers

None.

## Where to look

- `joharness.sh:checks_in_reach` — the new reach test.
