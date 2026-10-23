---
workstream: refusal-is-not-credentials
status: in-progress
branch: refusal-is-not-credentials
pr: none
plan: refusal-is-not-credentials
issue: none
session: https://claude.ai/code/session_01GCgdvphDZPwKLGLRQsdZxt
agent: sonnet
updated: 2026-10-23
next: Add the refusal bullet to manage.md §3, one sentence to orchestrated.md, pins in selftest/orchestrated.sh; run ci and verify
---

## Goal

A tool or permission refusal is a design constraint, not a human's decision.
Manager works around it with a different shape of the item; blocks
`credentials:` only when no shape exists.

## Decisions

## Review

Clean pass pending.

## Blockers

None.

## Where to look

- `.claude/commands/manage.md` §3; `.agents/harness/selftest/reading-budget.sh` manage.md bound.
