---
workstream: retired-stems-ledger
status: in-progress
branch: claude/retired-stems-ledger
pr: none
plan: retired-stems-ledger
issue: 423
session: https://claude.ai/code/session_01XFtu7RNcSRAqDV8SVJyuXg
agent: opus
updated: 2026-10-12
next: Run ci and verify, then verifier review at opus, record ## Review, retire, PR
---

## Goal

Issue #423 piece B: a carried branch plan retired as done lands on main as a
line in `docs/plans/RETIRED.md`, and `ci` refuses a diff that re-adds a
ledgered stem.

## Decisions

- Line shape `- <stem> <ref>`, one token ref: `retired_ref` reads field 3 of
  a line whose field 1 is `-` and field 2 the exact stem. Indented example in
  the file header cannot match a real stem.
- `<ref>` a carry manager writes = its own branch. The PR number does not
  exist yet at the retire commit (Loop step 7: retire is the LAST commit
  before the PR opens), and a commit cannot name its own sha.
- `ci` reads the ledger on `origin/<base>`, not the merge base: the branch
  that re-adds the stem is the owner's, cut BEFORE the retire landed.
- Every carry retire appends, built or found done, not only found-done: the
  owner's later merge re-adds a built-and-retired carried plan the same way.
- The held-plan exemption (repairs, core-only) does not cover the ledger.
- Every `TEMPLATE` site in `joharness.sh` and `queue-context.sh` changed, as
  the plan says, handover-only walks included (harmless, one rule).
  `handover-context.sh`/`handover-guard.sh` walk docs/handover only: out of
  scope, unchanged.
- `docs/plans/RETIRED.md` lands on main with its header and no line;
  manage.md gives the header for a consumer that has none.

## Rejected

- Restoring with `git checkout HEAD --` before committing the fix: HEAD was
  still main's scripts, the edits were lost and redone. Commit first.

## Review

## Blockers

None.

## Where to look

- `docs/plans/retired-stems-ledger.md` — the plan.
