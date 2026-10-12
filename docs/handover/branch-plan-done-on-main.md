---
workstream: branch-plan-done-on-main
status: in-progress
branch: claude/branch-plan-done-on-main
pr: none
plan: branch-plan-done-on-main
issue: 423
session: https://claude.ai/code/session_01DBge7Ng2dPpNZwrYjn7XCX
agent: opus
updated: 2026-10-12
next: Verifier review at opus, then finish (step 7)
---

## Goal

Issue #423 pieces C and age-half of D: each `plans on a branch` row in
dispatch says whether its stem is already done on main and how long it has
been held.

## Decisions

- Row shape: six tab fields `<kind> <branch> <stem> <urgency> <agent> <held days>`,
  kind `live|leftover|done`. Both `cmd_dispatch` readers route on `$1`, not NF.
  Leftover wins over done (signal 1 keeps its own text and block).
- Guard bound is the merge base of the commit that ADDED the plan, not of the
  tip: an owner that merged main up after a carry still reads DONE ON MAIN
  (case g). Evidence reachable from the add commit itself is the branch's own
  older history and counts for nothing.
- Evidence walk: `git log --stdin --full-history -m -G'^status:[[:space:]]*done'`
  over every origin ref but the row's own, `^<that merge base>`, under
  `docs/handover`; the file as the commit left it, else its parent's (a retire).
- Block prints one line per (stem, kind); `held` is the oldest branch's age.
  A DONE row drops the `URGENT` prefix: it leads with `DONE ON MAIN`.

## Rejected

- `cl_merged_claims`: no `status:`, capped at `FB_LIMIT` merges (plan text).

## Review

- r1: proof the new cases fail without the fix: `git checkout origin/main -- joharness.sh; bash .agents/harness/selftest.sh` 2026-10-12 → 2589 passed, 8 failed: (a), (b), (c), both (d) live rows, (f), (g), held-count — all new cases; restored script → 2597 passed, 0 failed. (no change)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_branch_plans` — the row producer.
- `joharness.sh:cmd_dispatch` — the NF readers.
