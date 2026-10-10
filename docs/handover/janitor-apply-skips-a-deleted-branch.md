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
next: Run ci and verify, then verifier review at opus
---

## Goal

`janitor --apply` must never re-create a branch deleted on origin (#397):
ask origin (`ls-remote`), not the local ref.

## Decisions

- `ls-remote` runs after the local-ref check, so the default-refspec case
  keeps its `skip … no such branch` path (plan: must not regress).
- `ls-remote` exit 2 = gone (rc 0, nothing pushed); any other non-zero =
  origin unreachable: skip with rc 1, never push on an unanswered question.
- Mutation, 2026-10-10: `janitor_apply` ls-remote + lease removed, `bash
  .agents/harness/selftest.sh` gave 2385 passed, 3 failed (the narrow-refspec
  cases); restored, 2388 passed, 0 failed.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:janitor_apply` — the push that re-created the branch.
