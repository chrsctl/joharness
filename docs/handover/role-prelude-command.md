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
next: Research the four role commands' §0-§1 on origin/main, then build cmd_role
---

## Goal

Replace the role commands' hand-written prelude (authority, fetch, report,
branch, claim, twin check, retire) with `./joharness.sh role <name>` printing
`GO` or `STOP: <reason>`; the commands keep only judgement.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `docs/plans/role-prelude-command.md` — the plan.
