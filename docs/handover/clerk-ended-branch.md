---
workstream: clerk-ended-branch
status: in-progress
branch: clerk-ended-branch
pr: none
plan: clerk-ended-branch
issue: none
session: https://claude.ai/code/session_01Ft341NtFw67fY7fCT5noKB
agent: opus
updated: 2026-10-22
next: Run ci and verify, record the red-without-fix line, verifier review, retire, PR
---

## Goal

A clerk pass that pushed a plan, dropped it and recorded a no-op holds the
clerk cycle as `in-flight` for a day. Recognise such a branch as `ended`,
failing closed.

## Decisions

- The new cases are labelled (i): the dispatch fixture already has an (e).
- No net change is read with `git diff-tree --quiet -r <merge base> <tip>`
  (plumbing, no user diff config), not porcelain `git diff --quiet`.
- `ended` rows are dropped by `scout_branches` (dispatch, the in-flight count)
  but `cmd_clerk` names them under their own `ended     :` line, so the
  acceptance row is visible.
- `origin/clerk-2026-10-22` no longer exists on origin (ls-remote 2026-10-22
  19:23 UTC): the live acceptance row cannot be seen; the fixture stands in.

## Rejected

- None yet.

## Review

- r0: not reviewed yet (no change)

## Blockers

None.

## Where to look

- `joharness.sh:clerk_walk` — row writer.
- `.agents/harness/selftest/clerk.sh` — cases (b)/(c).
