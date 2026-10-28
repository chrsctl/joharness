---
workstream: human-edge-slot
status: in-progress
branch: claude/orchestrator-chrsctl-gx-ttdnhr
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK6RbGUqbctFGqmGggf
agent: sonnet
updated: 2026-10-28
next: Run ci and verify, record review, open the pull request
---

## Goal

chrsctl/gx orchestrator, 2026-10-28: `dispatch` printed `0 of 4 free` over
three managers, the fourth slot held by `human/compose-e2e-ci-check`, retired
with its pull request waiting on a human merge. The human: "Compose ci should
not use a slot."

## Decisions

- A retired edge on a `human/` branch holds no slot and raises no STALL?:
  Loop step 2 makes every `human/<stem>` pull request a human's to merge, so
  no manager is left. Its items stay withheld; the row keeps
  `retired, no claim file` so the health table's HELD BY HUMAN row still
  matches it.
- orchestrate.md §3 `held-human` correction now skips rows dispatch already
  freed, or it double-counts.

## Review
