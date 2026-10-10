---
workstream: rescope-re-offered-after-merge
status: in-progress
branch: manage/rescope-re-offered-after-merge
pr: none
plan: rescope-re-offered-after-merge
issue: 300
session: https://claude.ai/code/session_015ufRMGse26o7Pqj5wxDqmt
agent: opus
updated: 2026-10-10
next: Read the rescope block in cmd_dispatch and dispatch_rescope_branches; design the settled read that survives the surveyor merge
---

## Goal

Settle `docs/research/rescope-re-offered-after-merge.md` (issue #300): a
merged surveyor's "holds are genuine" conclusion stops suppressing the
OVERLAP-BOUND spawn instruction once its branch merges or the holder set
shrinks. Graduate the answer into `joharness.sh` and delete the node.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_rescope_branches` — walk skips merged refs.
- `joharness.sh:cmd_dispatch` rescope block — key, `rescope_settled`.
