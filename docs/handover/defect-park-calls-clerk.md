---
workstream: defect-park-calls-clerk
status: in-progress
branch: manage/defect-park-calls-clerk
pr: none
plan: defect-park-calls-clerk
issue: none
session: https://claude.ai/code/session_01J1YMK6ujSkf22kYBVj7zeA
agent: opus
updated: 2026-10-28
next: Run ci and verify, then verifier at opus, then step 7
---

## Goal

A manager parked on a `defect: #<n>` issue no plan names makes the clerk due
at once (after `JOHARNESS_DEFECT_CLERK_HOURS`), not after the 24h cadence.

## Decisions

- A1: confirmed — `dispatch_defect_state` checks `plan_names_issue` (base, live branch rows), but keeps the answer local and an unreadable scan reads as unnamed; so the early check asks `clerk_issue_nums docs/plans all` itself (`?` = nothing early).
- A2: refuted — `clerk_due` runs and `clerk     :` prints BEFORE the in-flight walk. Promotion lives inside `clerk_due` (`clerk_park_early`), which walks the parked claims itself: one `git grep` for `next: defect:` over unmerged refs, then `dispatch_defect_state` per hit. `dispatch` and `clerk` read one value.
- A3: confirmed — `clerk.md` §2 takes `defect:` issues whose body opens `blocking:` first, and manage-reference § Defect makes every park's issue open `blocking:`. No change.
- Planned = the clerk's own `planned` list (base + every unmerged branch, leftovers too): broader than dispatch's live rows, so it errs toward no early clerk, and the clerk never spawns early for an issue it would then skip.
- A clerk landed (or no-op recorded) after the first park ends the early due: else a clerk that skips the issue (human-review, a verdict already posted) would respawn every pass. The cadence and PARKED UNPLANNED take over, as the plan's Out of scope says.

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:clerk_due` — shared cadence reader.
- `joharness.sh:clerk_park_early` — the early due.
