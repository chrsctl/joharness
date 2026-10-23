---
workstream: orchestrate-diet-guards
status: in-progress
branch: manage/orchestrate-diet-guards
pr: none
plan: orchestrate-diet-guards
issue: none
session: https://claude.ai/code/session_01QrfPewJErAQYw7ZCzLK9Zz
agent: sonnet
updated: 2026-10-23
next: Wait for ci+verify green, run scratch-copy acceptance (bound fails, pin fails), record in Review, verifier, retire, PR
---

## Goal

Plan orchestrate-diet-guards: bound orchestrate.md, pin moved rules, fix citations.

## Decisions

- Built: orchestrate.md bound (21480, base-dir arg on rb_bound), 12 reference pins, citations to reference in keeper.md, scout.md, orchestrated.md. Unverified until ci green.

## Rejected

## Review

- r1: orchestrated.md cited orchestrate.md "Report, every pass" for `fresh session is cheaper`, text only in the reference "Fresh session line" (verifier) (fixed)
- r2: keeper.md:76 cites orchestrate.md §4 for the keeper ring; orchestrate.md says "(§4, RETIRE)" itself (verifier) (wontfix: consistent with orchestrate.md's own cite)
- r3: orchestrated.md:538 claim "only orchestrate.md" holds send_later/create_session is false on main; not a moved-text citation (verifier) (wontfix: pre-existing, outside plan scope)
- r4: acceptance, scratch copies: orchestrate.md +2500 bytes = FAIL "23981 bytes, bound 23628"; restored = PASS "21480 bytes"; reference with "Looped, killed by the orchestrator" cut to "Looped, killed" = FAIL on that pin, restored (no change)
- r5: remaining `orchestrate.md` hits all cite text it holds: keeper.md:53 RUN END, :61 Pass entry/Retired, :74 "## 0. Start" heading, :76 §4 ring; orchestrated.md:6 link, :111 harness hash, :505 RUN END, :552/:553/:615 keeper-titled rule (no change)
- r6: ci: pass; verify: 6 passed, 0 failed (no change)

## Blockers

None.

## Where to look

- `docs/plans/orchestrate-diet-guards.md` — the plan.
