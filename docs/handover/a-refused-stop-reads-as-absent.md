---
workstream: a-refused-stop-reads-as-absent
status: in-progress
branch: manage/a-refused-stop-reads-as-absent
pr: none
plan: a-refused-stop-reads-as-absent
issue: 249
session: https://claude.ai/code/session_01ScNihrtaDVHdffQMpf9Qhq
agent: sonnet
updated: 2026-10-10
next: Retire plan+workstream, open PR, merge
---

## Goal

Issue #249: a refused stop call (archive_session/interrupt_session) has no
written outcome. Make refused = absent for that target this pass.

## Review

- r1: (verifier) archive refused with no confirmed interrupt respawns over a live session (fixed: follows interrupt row, no replace)
- r2: (verifier) plain `kill` has no row (wontfix: kill is not a tool; doc line reworded to name refusals only)
- r3: (verifier) rule sat between the colon and the table (fixed: moved after the table)
- r4: (verifier) "erroring" broader than refusals (wontfix: plan Scope says refused or erroring; never-retry matches plan)
- r5: (verifier) selftest pins one sentence (fixed: second needle pins the archive clause)
- r6: (verifier) doc fit loose (no change)

## Blockers

None.
