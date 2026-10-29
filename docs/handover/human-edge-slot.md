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
- r1: health table `gone | edge row naming an item | RESPAWN` contradicted the human/ row's "never respawn" (verifier) (fixed: row after HELD BY HUMAN, never respawn)
- r2: human/ row asserted a pull request exists; dispatch reads no PR state, so a manager dying before opening one went silent (verifier) (fixed: row says the health pass confirms one is open; health row reports none open)
- r3: a human/ edge only arises from a claim branch named human/<stem>, not the documented core-only worktree (verifier) (no change: the gx case is exactly that, human/compose-e2e-ci-check carrying compose-ci-check and e2e-ci-check)
- r4: orchestrate.md §3 "counts" undefined; both rows carry `retired, no claim file` (verifier) (fixed: keyed on `a human/ branch`)
- r5: human/ row dropped the push-age-unknown caveat (verifier) (fixed)
- r6: omicron case merges into the shared fixture main (verifier) (wontfix: eta case does the same and the later counts read green; 3907 passed, 0 failed, selftest.sh 2026-10-29)
