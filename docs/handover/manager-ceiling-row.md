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
next: Selftest, revert-proof the fixture, ci + verify, verifier review, retire, PR
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

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — claimed-row flag block.
