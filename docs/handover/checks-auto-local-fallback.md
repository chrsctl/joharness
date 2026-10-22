---
workstream: checks-auto-local-fallback
status: in-progress
branch: claude/checks-auto-local-fallback
pr: none
plan: checks-auto-local-fallback
issue: none
session: https://claude.ai/code/session_014wCvWi56XbqMaLKk8xdBds
agent: opus
updated: 2026-10-22
next: Run ci + verify on the fixed head, re-verify the r-fixes, then file the ci.yml human-remainder issue and retire
---

## Goal

Repository variable `JOHARNESS_CHECKS=local` alone switches a child repo to
the local gate: `finish` reads the head's `lint` check run; skipped = run
`ci` + `verify` here.

## Decisions

- Every `lint` run on the head must be `completed`/`skipped`, not only the
  highest id (plan said highest id): `check_name=lint` also returns a
  consumer workflow's own job named `lint`, and a skipped one of those must
  not switch the gate. The plan's re-run case still holds (fails closed).
- `CHECKS_LINT_SAID` (global, beside the function) keeps why: finish prints
  one line for `unread` and `none`, so "could not read" never looks like a
  read. The function's return contract is the plan's, unchanged.
- jq reads with `-s` and needs exactly one document with an array
  `check_runs`; anything else is `unread`.
- Conf-ignored warning stays when lint skipped; only its "This finish is
  github mode" clause goes.
- Human remainder: ci.yml `lint` comment "SET THE SESSION ENVIRONMENT TOO"
  paragraph goes stale; one `human-review` issue, `Refs` in the PR body.

## Rejected

- Highest-id `lint` run alone (plan text): r3 below.

## Review

- r1: (verifier) unreadable GitHub answer was silent: finish printed plain github mode, a skipped lint then read green with nothing checked (fixed: `unread` line, selftest)
- r2: (verifier) finish before Actions creates the lint run read the same silent way (fixed: `none` line, selftest)
- r3: (verifier) a consumer job named `lint` that skipped, with a higher id than the harness lint that passed, switched the gate (fixed: every lint run must say skipped; selftest `collide`)
- r4: (verifier) consumer-repos.md "A red base branch" said finish never reads a check run (fixed)
- r5: (verifier) github-mode text still said "does not read them (no network, no token)" and pass line "(not read here)" (fixed: both reworded, selftest needle updated)
- r6: (verifier) local-gate headers named the environment switch when lint skip fired it (fixed: `checks_local_why`, selftest)
- r7: (verifier) conf-ignored warning suppressed whole under lint skip, contradicting the doc (fixed: warning kept, github-mode clause dropped; selftest)
- r8: (verifier) `status == "completed"` clause untested (fixed: `queued` fixture; mutant 3 failed)
- r9: (verifier) slug validation untested (fixed: `/extra` origin case; mutant 4 failed)
- r10: (verifier) concatenated documents, object `check_runs` read as skipped (fixed: `jq -s`, one document, array; fixtures; mutants 3 and 1 failed)
- r11: (verifier) no `timeout` binary leaves `gh api` unbounded (wontfix: plan bounds it "when `timeout` exists"; curl carries --max-time)
- r12: (verifier) workstream file not updated with the code (fixed: this commit)
- r13: mutants on the checks topic alone, scratch worktree 2026-10-22: base 142 passed; `return 1` 13 failed, `return 0` 29+ (46) failed, `any` 9, no status 3, no slug 4, no length 3, no type 1, no unread line 2, no none line 1 (no change)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_finish` — where `is_local` is decided.
- `joharness.sh:checks_lint_skipped` — the GitHub read; fails closed.
