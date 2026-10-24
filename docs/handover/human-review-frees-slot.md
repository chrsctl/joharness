---
workstream: human-review-frees-slot
status: in-progress
branch: claude/human-review-frees-slot
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_017pMbD2M6TccgTkfZh9TDpS
agent: opus
updated: 2026-10-24
next: Re-run selftest and ci, then open the pull request
---

## Goal

User: a manager PR marked `human-review` must not hold a slot, since a
human cannot answer at once. Blocked branches already hold none. But a
manager finds the label at merge (manage.md §4), after the retire commit
has deleted the workstream file. A retired branch holds a slot until it
merges.

## Decisions

- Manager restores its retired workstream file as `status: blocked`. No
  dispatch code change: a blocked claim already frees the slot. The
  selftest runs the reference's own restore commands.
- Rule text lives in manage-reference.md (new § Label at merge), because
  manage.md is 59 bytes under its reading budget.

## Rejected

- dispatch reading PR labels: harness commands never call the GitHub API.

## Review

- r1: resume path named no actor (verifier) (fixed: points at orchestrate-reference § Relay, the path every block resumes by)
- r2: a retired branch whose label read failed, or that a human labels after the read, still holds a slot (verifier) (wontfix: dispatch reads no pull request state; harness commands never call the GitHub API)
- r3: selftest pinned dispatch, not the procedure (verifier) (fixed: case extracts and runs the reference's own commands)
- r4: fixture state after the case matches what later cases expect (verifier) (no change)
- r5: reference did not say how to find the retire commit (verifier) (fixed)
- r6: `next:` carried no question (verifier) (fixed)
- r7: lint warns the restored claim's plan is gone from the tree; it is a warning, and dispatch reads the row as blocked (verifier) (no change)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_retired_edges`: a branch past retire with no workstream file holds a slot.
