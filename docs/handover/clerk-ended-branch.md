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
next: Retire, open the PR, merge on green GitHub checks
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

- r1: (verifier) a merged no-op stamped ahead of now but inside the window marked a live clerk ended (fixed: no proof when the stamp is ahead of now; case (i) "stamped ahead of now")
- r2: (verifier) any merged no-op after the tip proves the end, not this pass's own: a twin's no-op could end a live clerk mid-pass (wontfix: a no-op names no branch to tie it to, the twin check already stops a second clerk, and the cadence clock reads not due either way)
- r3: (verifier) .agents/docs/orchestrated.md clerk row still said every young unmerged clerk branch takes a slot (fixed)
- r4: (verifier) the live acceptance row and the red-without-fix line were not recorded (fixed: origin/clerk-2026-10-22 gone at 19:23 UTC 2026-10-22, said in the PR body; red line below)

Red without the fix (`./joharness.sh ci` in a worktree with origin/main
977c74e's joharness.sh and this branch's clerk.sh, 2026-10-22 ~20:00 UTC):
`FAIL (i) ended: no net change and a later no-op record hold nothing`, and 5
more (i) lines. With the fix: every clerk case passes; the one red is
`80 KB of prose keywords: 5s (wanted <= 4s)`, red on main here too (#535).

## Blockers

None.

## Where to look

- `joharness.sh:clerk_walk` — row writer.
- `.agents/harness/selftest/clerk.sh` — cases (b)/(c).
