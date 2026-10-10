---
workstream: janitor-apply-skips-a-deleted-branch
status: in-progress
branch: claude/janitor-apply-skips-a-deleted-branch
pr: none
plan: janitor-apply-skips-a-deleted-branch
issue: 397
session: https://claude.ai/code/session_01VK36eqjgoWdgS5dZHGEedK
agent: opus
updated: 2026-10-10
next: Implement janitor_apply ls-remote check plus selftest cases per the plan Scope
---

## Goal

`janitor --apply` must never re-create a branch deleted on origin (#397):
ask origin (`ls-remote`), not the local ref.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:janitor_apply` — the push that re-created the branch.
