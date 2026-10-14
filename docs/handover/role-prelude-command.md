---
workstream: role-prelude-command
status: in-progress
branch: manage/role-prelude-command
pr: none
plan: role-prelude-command
issue: none
session: https://claude.ai/code/session_014WnbFzA7gTeyhacD1ne3ez
agent: opus
updated: 2026-10-14
next: Rewrite clerk/scout/curate/conduct.md §0-§1 to call ./joharness.sh role; orchestrated.md Roles table
---

## Goal

Replace the role commands' hand-written prelude (authority, fetch, report,
branch, claim, twin check, retire) with `./joharness.sh role <name>` printing
`GO` or `STOP: <reason>`; the commands keep only judgement.

## Decisions

- The text wins over the plan's step list (plan Traps). scout.md §0.3 reads
  no brief as `off`, a plain exit: no `NO BRIEF` claim-and-retire exists in
  the text, so `role scout` stops on `off` and claims nothing; the selftest
  case asserts that instead.
- curate.md names no in-flight check and no resume; `role curate` stops only
  on "no PROPOSE findings" (curate.md §0.2), plus `UNREADABLE`/`IN FLIGHT`
  should cmd_curate ever print one. Resume = a claim file of the role's own
  on HEAD, so it covers curate and scout; clerk and conduct write none.
- clerk's plain exits: IN FLIGHT and UNREADABLE (clerk.md §0.2: the only
  exit on a clean read; `off`/`not due` carry on).
- Every role's branch takes `-b`, `-c` on a name collision, not only the
  clerk's: scout.md names a claim FILE, not a branch, and a second same-day
  scout would otherwise hit non-fast-forward.
- Output: the reports print as they always did; the LAST line is `GO
  <branch>` (rc 0) or `STOP: <reason>` (rc 1). `--retire` prints `GO
  <branch> (retired)`.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `docs/plans/role-prelude-command.md` — the plan.
