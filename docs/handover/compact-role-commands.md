---
workstream: compact-role-commands
status: in-progress
branch: manage/compact-role-commands
pr: none
plan: compact-role-commands
issue: none
session: https://claude.ai/code/session_01MxsnXk5U4DRcTvfd8urrBK
agent: opus
updated: 2026-10-24
next: Wait for plan-checker findings, record them, then fan out workers on the one-pass role files
---

## Goal

User asked to simplify and compact the protocol: cut the eleven non-orchestrator
role command files (plan scope) to 1150 lines or fewer, one home per rule, no
history, behaviour unchanged.

## Decisions

- Manager does manage.md and manage-reference.md itself (needle-dense); workers take the other files.

## Rejected

- Manager does manage.md and manage-reference.md itself (needle-dense); workers take the other files.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/selftest/orchestrated.sh:manage-reference` — pointer test and needles.
- `.agents/harness/selftest/reading-budget.sh:budget` — byte caps.
