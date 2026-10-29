---
workstream: dispatch-edge-slot-window
status: in-progress
branch: manage/dispatch-edge-slot-window
pr: none
plan: dispatch-edge-slot-window
issue: 701
session: https://claude.ai/code/session_01J1YMK53poa2Ag5SDkEp9AR
agent: opus
updated: 2026-10-29
next: Second verifier pass on the r14-r18 fixes, then step 7
---

## Goal

Issue #701: a retired no-claim-file edge branch holds a manager slot forever.
Bound the hold by `JOHARNESS_EDGE_SLOT_HOURS`; past it the row stays listed,
items stay withheld, slot is freed.

## Decisions

- A1: confirmed — `n_inflight=$((n_inflight + 1))` follows the `human/*` case in the edge loop.
- A2: confirmed — `edge_items` is appended before the `human/*` case and the count.
- A3: confirmed — `human/*)` case adds to `n_human_edge` and `continue`s.
- A4: confirmed — `.agents/harness/AGENTS.md` step 7, last line.
- A5: confirmed — `dispatch_age_min` prints `(now - ts) / 60`.
- A6: confirmed — `.claude/commands/orchestrator.md` §3 Spawn, held-human rule.
- Aged NOT DRAINED replaces only the exit verdict: the in-flight, pending, role and release verdicts are no exit and carry their own orders (r17).
- DRAINED case gets its own mini repo (`dispatchaged`): the shared fixture always has a free item, so a DRAINED assertion there passes both ways (measured: its verdict read `NOT DRAINED — 1 free item(s) now`). Without the fix the mini repo reads `verdict   : DRAINED — nothing free; 1 manager(s) in flight` (origin/main joharness.sh, 2026-10-29).
- No workers: five small edits, two of them one sharing joharness.sh with the selftest that measures it; a brief would cost more than the edit.

## Rejected

## Review

- r1: (plan-checker) aged row text vs health table `gone` row RESPAWN to FINISH: a respawn after a control-plane read is not blind, and its first push un-ages the row so it holds a slot again — at most one over cap for one pass; the table is out of scope (wontfix: plan puts the health table out of scope; over-cap is one pass)
- r2: (plan-checker) DRAINED acceptance not runnable, `no DRAINED` matches `NOT DRAINED` (fixed)
- r3: (plan-checker) which DRAINED printf is ambiguous (fixed)
- r4: (plan-checker) origin/main red check gives no command (fixed)
- r5: (plan-checker) acceptance items silent on failure shape (no change)
- r6: (plan-checker) ship-scope item has no exact text and vanishes when the plan is deleted (no change)
- r7: (plan-checker) Goal says the pull request never opened; issue did not verify it (no change)
- r8: (plan-checker) Escape Entry names a rewording commit (fixed)
- r9: (plan-checker) restore the date has two readings (fixed)
- r10: (plan-checker) orchestrated.md row meaning column unspecified (no change)
- r11: (plan-checker) prefix should be substring (fixed)
- r12: (plan-checker) `halt` already frees an edge slot but re-offers its plan (no change)
- r13: (plan-checker) spawn prompt carried the repo path beyond the plan path (no change)
- r14: (verifier) aged row and reference sentence said none open = report to the human, against health-table row `gone | edge row naming an item | RESPAWN`, and the sentence sat where only HELD BY HUMAN reaches (fixed: row, verdict note and sentence defer to the health table's edge rows when no pull request is open; the table stays out of scope)
- r15: (verifier) plan Acceptance says `verify` runs the dispatch selftest; `verify` here is the layer smoke only (fixed: item names `ci`)
- r16: (verifier) an edge naming no item aged at 4h lost its STALL? REPORT and read `items stay withheld` (fixed: itemless edges never age; case red without the guard, 2 FAIL, ci 2026-10-29)
- r17: (verifier) aged NOT DRAINED masked the in-flight, pending, role-due and release-due verdicts (fixed: it replaces only the exit verdict)
- r18: (verifier) plan red-check command rewrites the tree; branch 1 behind origin/main (fixed: run only with no verifier live; origin/main merged in)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch` — edge loop, `n_edge`.
- `.agents/harness/selftest/dispatch.sh:mgr-eta` — fixture to extend.
