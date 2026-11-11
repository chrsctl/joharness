---
workstream: hold-followups
status: in-progress
branch: claude/hold-followups
pr: none
plan: hold-followups
issue: none
session: https://claude.ai/code/session_01J1YMK4wp9cyBubHVHvhdvK
agent: sonnet
updated: 2026-11-11
next: Full selftest, verify, second verifier pass on the r1-r5 fixes, then PR.
---

## Goal

Fix the four findings reported on PR #734, as the requester asked.

## Decisions

- Finding 1: the hold stays while a second plan names the issue after the
  first retired (reverted from "lift" after r1): a plan leaves the base
  unbuilt too (abandoned, superseded), so lifting re-opens #1449. A wait
  costs little; the fix row spawns; STUCK tells the human.
- A fix in a wave behind a held row does not WAIT: that row never spawns
  while the hold stands (found building finding 2).
- Finding 4: no `worktree prune` in cleanup (a selftest pins that runs share
  the repo); remove the run's own admin entry instead.

## Rejected

- Lifting the hold once any plan naming #<n> retired (first build of
  finding 1): r1 showed an abandoned or superseded plan lifts it onto a red
  base. Undone in the same branch; the research step was r1's input plus the
  #1449 timeline.

## Review

- r1: (verifier) the finding-1 change lifts the hold when a plan retires unbuilt while a second plan is the real fix: #1449 again (fixed: reverted to holding, pinned by "one plan retired, a second open: the hold stands")
- r2: (verifier) orchestrated.md said both "a plan naming #<n> is no fix" and that a retire alone lifts (fixed: rewritten with r1)
- r3: (verifier) the WAIT branch of the held-fix line was untested; building its test showed the fix WAITs on a held row forever (fixed: a held wave partner is moot, pinned by "a fix never waits on a row the red base holds")
- r4: (verifier) c2_cleanup slept after its last failed remove (fixed: no sleep after the third try)
- r5: (verifier) c2_wt_add left the admin entry when its remove failed, wasting retries (fixed: c2_drop_admin on a failed remove)
- r6: (verifier) GNU-only `sed -i` and `\n` in the new selftest (no change: 16 selftests use the form; the selftest runs on Linux CI)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — `dpark`, the fix-row exemption.
- `.agents/scripts/c2-run.sh:c2_cleanup`.
