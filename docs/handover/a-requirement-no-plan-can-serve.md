---
workstream: a-requirement-no-plan-can-serve
status: in-progress
branch: claude/a-requirement-no-plan-can-serve
pr: none
plan: a-requirement-no-plan-can-serve
issue: none
session: https://claude.ai/code/session_013FHjxEdXBhx4U6yUnLfFtg
agent: opus
updated: 2026-10-10
next: Retire workstream file, PR, merge
---

## Goal

Settle research node `a-requirement-no-plan-can-serve`: what stops dispatch
re-offering a requirement as UNPLANNED when no plan will ever name it.
Graduate the answer to `.agents/docs/product/README.md`, delete the node.

## Decisions

- UNPLANNED test stays; lifecycle gives: four exits for a planning pass
  (plans, verify plan via needs:, satisfied-measured, declined-recorded),
  else blocked. A recorded, citable requester decline = requester deciding.
- Claim gap (candidate 1) needs code: filed as plan requirement-row-claim,
  not built here (research file writes no code).

## Rejected

- planned-out marker on requirement: status field, product README forbids.
- clause-level decline vocabulary read by the test: largest change, exit 4
  already makes the decline legible in history.
- bound the spend: every pass ends normally, ceiling never fires.

## Review

- r1: (verifier) plan scope missed `lint_graph`, which reds a workstream `plan:` naming a requirement (measured by verifier, clone of fb762c5c + `plan: alpha-req`, `JOHARNESS_SELFTEST=never ./joharness.sh ci`: `DEAD ... plan 'alpha-req' — no such plan or question`); README understated it. (fixed — plan scope names it, README says ci reds)
- r2: (verifier) cand loops alone make no in-flight row: dispatch rows `sed` matches only docs/(plans|research), `drain_requirement` offers claimed rows, retired-edges skips adders. Code read. (fixed — plan scope names all three)
- r3: (verifier) README said "exactly one" exit; exits combine and an early exit-4 deletion leaves an open plan naming a gone requirement. (fixed — exits combine per clause, deletion once by the LAST PR, records ride in that plan)
- r4: (verifier) exit 3 contradicted Satisfied bullet and manage.md "plans only". (fixed — Satisfied bullet admits exit 3; manage.md line names the exits, one line beyond research-file scope, recorded here. Loop step 7 "+ requirement file when last plan" describes a plan PR and is not contradicted: no change)
- r5: (verifier) "Gap still open" paragraph goes stale when the plan lands, not in plan scope. (fixed — README + handover TEMPLATE in plan scope)
- r6: (verifier) stem naming both plan and requirement claims both. (fixed — plan says plan/research resolve first)
- r7: (verifier) workstream file anchored the deleted node. (fixed — recovery command instead)
- r8: (verifier) exit 3 named no record location. (fixed — deletion commit message, per clause)

## Blockers

None.

## Where to look

- Retired node: `git show origin/main:docs/research/a-requirement-no-plan-can-serve.md`.
- `.agents/docs/product/README.md` — graduation target, lifecycle exits.
