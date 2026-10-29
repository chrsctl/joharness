---
workstream: parked-pr-merge-stalls-fleet
status: in-progress
branch: manage/parked-pr-merge-stalls-fleet
pr: none
plan: parked-pr-merge-stalls-fleet
issue: none
session: https://claude.ai/code/session_01J1YMK7aZoBRVvB5uRaJTG7
agent: opus
updated: 2026-10-29
next: Write the draft-on-park rule and its why into manager-reference.md § Defect, file clerk and dispatch plans, delete the research file
---

## Goal

Settle `docs/research/parked-pr-merge-stalls-fleet.md`: does a `defect:` park
leave a mergeable pull request whose merge turns `main` red, and does any
role plan that red in time. Graduate the answer, delete the file.

## Decisions

- Finding 1 re-taken in canonical, GROUNDED: PR #693 opened 09:33:38Z after
  retire `e89c8d12`; block `047dbf06` (09:34Z, `hardware:`) put
  `docs/handover/c2-run-prune-race.md` back on the head; non-draft, merged by
  hand 11:26:10Z (`mergeable_state: clean`). `cleanup` lists it stale on
  `origin/main`; the session-start hook names it as this branch's job. So
  the leak is any block after retire, not only `defect:`.
- Finding 2 GROUNDED in code: `joharness.sh` dispatch prints `clerk : IN
  FLIGHT, so none is due` whatever `clerk_due` (incl. `clerk_park_early`)
  says; an in-flight clerk holds until `JOHARNESS_CLERK_STALE_HOURS`.
- gx readings (merge times, ledger output, session timelines) WEAK: add_repo
  for chrsctl/gx denied here, not re-taken.
- Graduation = draft-on-park rule in `manager-reference.md` § Defect; the
  clerk and dispatch changes are code, filed as plans in this pull request.

## Rejected

None yet.

## Review

Not yet run.

## Blockers

None.

## Where to look

- `.agents/docs/manager-reference.md` § Defect — the park step.
