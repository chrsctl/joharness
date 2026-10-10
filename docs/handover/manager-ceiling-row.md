---
workstream: manager-ceiling-row
status: in-progress
branch: claude/manager-ceiling-row
pr: none
plan: manager-ceiling-row
issue: none
session: https://claude.ai/code/session_01KJ92BHuw5KVtRvCQuyCsgr
agent: opus
updated: 2026-10-10
next: Confirm selftest green and rv copy red, then retire plan + workstream file, PR, merge
---

## Goal

Issue #298 items 1-2: a git-only signal in `dispatch` for a manager that has
held its claim N hours with no pull request, reported (never killed on).

## Decisions

- Claim age reads `%at` (author date), not the plan's `%ct`: a rebase or
  amend rewrites `%ct` to now and would reset the ceiling.
  `dispatch_block_age_min` reads `%at` for the same reason.
- Lifted (`JOHARNESS_MANAGER_HOURS=0`), the header prints `lifted` and no
  `CEILING?` token, so the plan's acceptance `grep -c CEILING?` is 0.
- orchestrate.md row says read it BESIDE the matched row: the table reads
  first-match, and the first row matches the RUNNING under-window manager
  this mark is about.

## Rejected

- None yet.

## Review

- r1: (verifier) selftest.sh's knob unset list lacks JOHARNESS_MANAGER_HOURS: `JOHARNESS_MANAGER_HOURS=12 bash .agents/harness/selftest.sh` reds the header and CEILING? cases. (fixed: added to the unset list)
- r2: (verifier) author date in the future hides CEILING?: claim with GIT_AUTHOR_DATE=now+99999999, GIT_COMMITTER_DATE=now-20h read `pushed 20h STALL?`, no CEILING? (verifier's t3.sh). (fixed: age = older of %at and %ct; fixture `mgr-future`)
- r3: (verifier) fixture set both dates equal, so %at vs %ct was unpinned. (fixed: fixture `mgr-rebased`, author 10h ago, committer now)
- r4: (verifier) tail line said "no pull request"; dispatch only reads the workstream `pr:` (no `gh` in joharness.sh). (fixed: "no pr: in the claim file")
- r5: (verifier) shallow clone: empty merge base, row silently lacks CEILING? (verifier's t4.sh, `--depth 1`). (wontfix: dispatch already unshallows on its fetch, and the `work:` line vanishes the same way; a third unknown line per row is noise for a report mark)
- r6: (verifier) docs/research/no-ceiling-on-one-item.md stays open though this answers its item 1. (wontfix: another queue item, one item per session; sent as a lead to the orchestrator)
- r7: (verifier) joharness.conf's commented knob list lacks JOHARNESS_MANAGER_HOURS. (wontfix: core path; flagged in the PR body for the human)
- r8: (verifier) `next:` printed raw can carry a forged CEILING? token. (wontfix: pre-existing for STALL?/LOOP?, report-only mark, no kill path)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — claimed-row flag block.
