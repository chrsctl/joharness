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
next: Run ci and verify, the origin/main red check, then verifier at opus, then step 7
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
- Aged NOT DRAINED branch sits before the in-flight DRAINED, so it covers every DRAINED form.
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

## Blockers

None.

## Where to look

- `joharness.sh:dispatch` — edge loop, `n_edge`.
- `.agents/harness/selftest/dispatch.sh:mgr-eta` — fixture to extend.
