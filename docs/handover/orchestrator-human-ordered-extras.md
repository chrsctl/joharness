---
workstream: orchestrator-human-ordered-extras
status: in-progress
branch: manage/orchestrator-human-ordered-extras
pr: none
plan: orchestrator-human-ordered-extras
issue: 425
session: https://claude.ai/code/session_01HQ4yhvTfCmrVxakjMcTnbq
agent: sonnet
updated: 2026-10-12
next: Confirm ci pass on review fixes; then retire plan+workstream file, PR, merge
---

## Goal

Give the human's order for an extra role session one defined path in orchestrate.md (plan orchestrator-human-ordered-extras).

## Review

- r1: no-wake-pending `pass=1` loses to completed wakes with higher `pass=` in the superseded check (verifier) (fixed: pass = highest seen plus one; deviates from plan's `pass=1`)
- r2: Never line unwrapped (verifier) (fixed)

## Blockers

None.
