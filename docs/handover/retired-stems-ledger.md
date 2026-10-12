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
  a line whose field 1 is `-` and field 2 the exact stem (backticks and CR
  stripped; no ref = `?`). The indented example in the header cannot match.
- `<ref>` a carry manager writes = its own branch. The PR number does not
  exist yet at the retire commit (Loop step 7: retire is the LAST commit
  before the PR opens), and a commit cannot name its own sha.
- `ci` reads the ledger on `origin/<base>`, not the merge base: the branch
  that re-adds the stem is the owner's, cut BEFORE the retire landed. It
  reads the branch's own working-tree ledger too (r2).
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

- r1: (verifier) curate case passed without the fix: curate never prints a stem, only counts (fixed: asserts `— 1 free plan(s)`)
- r2: (verifier) a branch adding a plan AND its own ledger line was ci-green; manage.md never named deleting the carried plan copy (fixed: ci also reads the branch's own ledger; manage.md names the copy's deletion)
- r3: (verifier) a ledger line with no ref or a backticked stem guarded nothing (fixed: stem match strips backticks, missing ref prints `?`)
- r4: (verifier) CRLF ledger line put a carriage return into the ci message (fixed: `tr -d '\r'`)
- r5: (verifier) override message misled when the line is removed in the re-adding branch itself (fixed: message and RETIRED.md say the removal lands on the base first)
- r6: (verifier) guard fires only on a ci run after the retire lands; a human merging on an older green check passes (fixed: orchestrated.md says so and names branch protection's up-to-date rule; that rule is a core path, `.github`/settings, not this branch's)
- r7: (verifier) RETIRED also excluded from docs/handover walks, a workstream named RETIRED turns invisible (wontfix: plan says change every TEMPLATE site; workstream stems are lowercase kebab)
- r8: fail-without-fix, 2026-10-12, scratch runner sourcing only retired-ledger: branch scripts 53 passed 0 failed; `git checkout origin/main -- joharness.sh .agents/harness/queue-context.sh` 36 passed 17 failed (every case (a) and (c) check, curate count included); pre-verifier-fix commit 48 passed 5 failed (r2-r5 cases); restored with `git checkout HEAD --` (no change)

## Blockers

None.

## Where to look

- `docs/plans/retired-stems-ledger.md` — the plan.
