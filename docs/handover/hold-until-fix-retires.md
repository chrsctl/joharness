---
workstream: hold-until-fix-retires
status: in-progress
branch: claude/hold-until-fix-retires
pr: none
plan: hold-until-fix-retires
issue: none
session: https://claude.ai/code/session_01J1YMK4wp9cyBubHVHvhdvK
agent: sonnet
updated: 2026-11-10
next: Run verify, open the PR, merge on finish: pass.
---

## Goal

Red-base HOLD lifts only when the fix retires, not when a plan names the
issue (chrsctl/gx, 2026-11-10, #1449).

## Decisions

- The fix plan row is the one exemption, read by its own `issue:` on the
  base: holding it would deadlock the hold.

## Rejected

None yet.

## Review

- r1: (verifier) a fix retired while a second plan naming #<n> is live keeps the hold, as it keeps RESUME (fixed: stated in orchestrated.md; the plan's Goal binds the hold to the RESUME condition)
- r2: (verifier) a fix row itself overlap-held or WAIT shows no red-base context in the verdict when it is the only row (wontfix: the row prints its own HOLD/WAIT line and clears when the overlap merges; no spawn is wrong)
- r3: (verifier) no pins for a claimed fix, a fix with open needs:, a CORE ONLY fix, research and requirement rows under the hold (wontfix: extra pins outside this plan, in PR body)
- r4: edge review, own read of the diff: verdict order, requirement row, research rows, shellcheck (no change)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — `dpark` / `dhold`.
