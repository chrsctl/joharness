---
workstream: parked-pr-merge-stalls-fleet
status: review
branch: manage/parked-pr-merge-stalls-fleet
pr: none
plan: parked-pr-merge-stalls-fleet
issue: none
session: https://claude.ai/code/session_01J1YMK7aZoBRVvB5uRaJTG7
agent: opus
updated: 2026-10-29
next: Retire, open the pull request, finish, merge
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
- `manager.md` pointer lands here, not in a plan: the selftest reds a
  reference section `manager.md` does not point to (`FAIL manager.md points
  to ref § Block on an open pull request`).
- `./joharness.sh ci` on `origin/main` 777457fe: `ci: pass` with the stale
  file on it — no canonical gate catches the merge.
- Graduation = draft-on-park rule in `manager-reference.md` § Defect; the
  clerk and dispatch changes are code, filed as plans in this pull request.

## Rejected

- `finish` refusing a head whose workstream file is not `done`: guards
  only an agent's merge; the stall came from a human's merge button.

## Review

- r1: (verifier) stale `docs/handover/c2-run-prune-race.md` left on `main`, no gate or plan; finish-gate alternative missing from Rejected (wontfix: deleting another item's file is not this item; Rejected now names the finish gate; a lead goes to the orchestrator after merge)
- r2: (verifier) both plans SHIP but Acceptance names no consumer-side check (fixed)
- r3: (verifier) plan files and `manager.md` edit exceed a research graduation's diff (wontfix: `manager.md` §2 puts follow-up work in a plan file in this pull request; the pointer is forced by the selftest)
- r4: (verifier) out-of-scope reason cites `joharness.conf` for knobs that live in `joharness.sh` (fixed)
- r5: (verifier) clerk plan's condition fires on a healthy in-flight clerk (fixed: no push since the park, plus a not-DUE case)
- r6: (verifier) § Label at merge has no draft step (fixed)
- r7: (verifier) durable doc names plan stems that get deleted (fixed)
- r8: (verifier) stub line mid-paragraph in `manager.md` (fixed)

## Blockers

None.

## Where to look

- `.agents/docs/manager-reference.md` § Defect — the park step.
