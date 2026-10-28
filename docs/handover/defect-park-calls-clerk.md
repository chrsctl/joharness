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
next: Run ci and verify on this head, then step 7
---

## Goal

A manager parked on a `defect: #<n>` issue no plan names makes the clerk due
at once (after `JOHARNESS_DEFECT_CLERK_HOURS`), not after the 24h cadence.

## Decisions

- A1: confirmed — `dispatch_defect_state` checks `plan_names_issue` (base, live branch rows), but keeps the answer local and an unreadable scan reads as unnamed; so the early check asks `clerk_issue_nums docs/plans all` itself (`?` = nothing early).
- A2: refuted — `clerk_due` runs and `clerk     :` prints BEFORE the in-flight walk. Promotion lives inside `clerk_due` (`clerk_park_early`), which walks the parked claims itself: one `git grep` for `next: defect:` over unmerged refs, then `dispatch_defect_state` per hit. `dispatch` and `clerk` read one value.
- A3: confirmed — `clerk.md` §2 takes `defect:` issues whose body opens `blocking:` first, and manage-reference § Defect makes every park's issue open `blocking:`. No change.
- Planned = the clerk's own `planned` list (base + every unmerged branch, leftovers too): broader than dispatch's live rows, so it errs toward no early clerk, and the clerk never spawns early for an issue it would then skip.
- A clerk that read the issues after the first park (a landed clerk's first commit; a no-op record's stamp) ends the early due: else a clerk that skips the issue (human-review, a verdict already posted) would respawn every pass. The cadence and PARKED UNPLANNED take over, as the plan's Out of scope says.

## Rejected

## Review

- r1: (verifier) ci red: shellcheck SC2120 on `ckc`, and a top-level `unset` the runner does not carry (fixed: no args, no unset; ci pass)
- r2: (verifier) a clerk cut before the park but merged after it suppressed the early due: dated by its merge (fixed: dated by its branch's first commit; selftest fails without it)
- r3: (verifier) a park reading RECHECK gets no early clerk (wontfix: the plan names PARKED only; RECHECK sends the manager back, and its re-park reads PARKED again)
- r4: (verifier) three `clerk.sh` refutes of `clerk DUE: spawn` miss the early line (fixed: refute `spawn ONE clerk`)
- r5: (verifier) the plan's Acceptance command `bash …/dispatch-park.sh` cannot run alone (no change: topics run through selftest.sh in `ci`; the plan file retires with this pull request)
- r6: (verifier) two parks on one issue counted as two (fixed: distinct issues, named; selftest fails without it)
- r7: no plan-checker ran: it is spawned before the first worker, and this build ran no worker (no change)

## Blockers

None.

## Where to look

- `joharness.sh:clerk_due` — shared cadence reader.
- `joharness.sh:clerk_park_early` — the early due.
