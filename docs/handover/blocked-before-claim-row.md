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
next: final verifier pass on the r12-r20 commit, then retire, PR, merge
---

## Goal

Give the orchestrator's health table one correct row for a manager blocked
by a permission prompt before its first push, and stop the merged row
matching a ledger entry still `new`.

## Decisions

- Claim-and-merge inside one pass (entry still `new` at merge) is NOT fixed
  here: out of the plan's scope, two fix rounds each drew findings (r2,
  r13-r16). Follow-up plan `new-entry-merged-between-passes` carries it.
- Confirm row is labelled BLOCKED BEFORE CLAIM too, so all three rows read
  as one family; respawn resets the entry to `@new` with no `held=`.

## Rejected

- Item-gone clause on the merged row itself: sits below the UNCLAIMED rows,
  never reached on IDLE (r2).
- Item-gone row above the `new` rows: crash rows still precede it, surveyors
  have no item path, a curate or another merge fakes it, requirements are
  not deleted on merge (r13-r16).

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
- r12: (verifier, pass 2) r5's "created after the `@new` write" can never hold — the entry is written after `create_session` returns, and the ledger stores no time. (fixed — clause dropped: title decides alone for a `new` entry)
- r13: (verifier, pass 2) merged-between-passes row sat below the crash rows, which also match `new`. (fixed — row removed, see r16)
- r14: (verifier, pass 2) that row had no item path for a surveyor's `rescope-<key>@new`. (fixed — row removed, see r16)
- r15: (verifier, pass 2) item gone from `origin/main` can be a curate or another merge while this manager is prompt-held. (fixed — row removed, see r16)
- r16: (verifier, pass 2) a requirement's planning manager does not delete its item on merge, so r2's fix covered plans only. (fixed — the merged-between-passes row was out of the plan's scope and kept drawing findings: removed, merged row is the plan's head-only condition; the claim-and-merge-inside-one-pass gap goes to follow-up plan `new-entry-merged-between-passes` with r13-r16 as its traps)
- r17: (verifier, pass 2) orchestrated.md still said the confirm row reports AT the limit after acting. (fixed — at the limit: report, touch nothing, both places)
- r18: (verifier, pass 2) orchestrated.md `done` row folded the merged-between-passes case into the reporter path the command forbade. (fixed — moot with r16; `done` says a `new` entry never matches)
- r19: (verifier, pass 2) orchestrated.md table had no row for ARCHIVED with a `new` entry. (fixed — `gone before claim` row)
- r20: (verifier, pass 2) step 4's "Entry age gates ENTRY ... decides nothing else" was stale. (fixed — names both first looks and the `gone before claim` report)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md`, `## 2. Health pass`.
- `.agents/docs/orchestrated.md`, "Blocked before its first push".
