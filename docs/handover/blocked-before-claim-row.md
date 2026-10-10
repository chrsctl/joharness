---
workstream: blocked-before-claim-row
status: in-progress
branch: blocked-before-claim-row
pr: none
plan: blocked-before-claim-row
issue: none
session: https://claude.ai/code/session_012J8LutqGHqhZDE49agfS81
agent: opus
updated: 2026-10-10
next: ci, retire workstream + plan file, PR, merge
---

## Goal

Give the orchestrator's health table one correct row for a manager blocked
by a permission prompt before its first push, and stop the merged row
matching a ledger entry still `new`.

## Decisions

- Claim-and-merge inside one pass leaves the entry `new`: a row ABOVE every
  `new` row reads item-gone-from-`origin/main` as done (r2). A never-born
  branch cannot fake the item vanishing.
- Confirm row is labelled BLOCKED BEFORE CLAIM too, so all three rows read
  as one family; respawn resets the entry to `@new` with no `held=`.

## Rejected

- Item-gone clause on the merged row itself: sits below the UNCLAIMED rows,
  never reached on IDLE (r2).

## Review

- r1: (verifier) ARCHIVED or not-found with entry still `new` matched no row once the merged row needed a head. (fixed — new `gone before claim` row: report, keep the entry)
- r2: (verifier) the item-gone clause on the merged row sat below the UNCLAIMED rows, so an IDLE claim-and-merge still reported as unclaimed. (fixed — merged-between-passes row moved ABOVE every `new` row; merged row back to the plan's head-only condition)
- r3: (verifier) BLOCKED BEFORE CLAIM confirm could respawn an item already merged. (fixed — same row as r2 reads first)
- r4: (verifier) confirm row interrupted and archived before checking the respawn limit. (fixed — at the limit: report, touch nothing)
- r5: (verifier) pre-action guard demanded a branch match a `new` entry cannot have. (fixed — title alone, session created after this run's `@new` write)
- r6: (verifier) `status_bucket` field row read RUNNING+BLOCKED as recovered. (fixed — BLOCKED decides the reverse way, RUNNING is the stuck reading)
- r7: (verifier) orchestrated.md `done` row and paragraph disagreed with the command row. (fixed — both name the merged-between-passes row)
- r8: (verifier) doc row said read before unclaimed but sat below it. (fixed — moved above)
- r9: (verifier) Tools row for missing `status_bucket` did not name the new rows. (fixed)
- r10: (verifier) "THREE things" and the first-look admission sentence were stale. (fixed — four things; both first-look rows, `seen=` or `held=`)
- r11: (verifier) RUNNING+BLOCKED flipping to IDLE+BLOCKED with `updated_at` unchanged leaves `held=` stale. (wontfix — harmless: UNCLAIMED keys on `seen=`, and the key is overwritten or dropped on the next BLOCKED reading)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md`, `## 2. Health pass`.
- `.agents/docs/orchestrated.md`, "Blocked before its first push".
