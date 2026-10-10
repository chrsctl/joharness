---
workstream: rescope-janitor-apply-skips-a-deleted-branch
status: in-progress
branch: claude/rescope-janitor-apply-skips-a-deleted-branch
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01G52cWY5EeoZbySNwwkGbDR
agent: sonnet
updated: 2026-10-10
next: Rewrite carried-plan-leftover scope to shared:joharness.sh, shared:.agents/docs/orchestrated.md; PR; merge
---

## Goal

Surveyor for rescope key janitor-apply-skips-a-deleted-branch: carried-plan-leftover is held on a bare `joharness.sh` claim.

## Review

- r1: (verifier) selftest fixture path undeclared in carried-plan-leftover scope (fixed: added shared:.agents/harness/selftest/dispatch.sh)
- r2: (verifier) plan edits in place, shared: arguably unneeded (no change: three sibling plans already declare shared:joharness.sh; bare entry caused the hold)
- r3: (verifier) workstream file must be deleted in last commit (fixed: retire commit)
