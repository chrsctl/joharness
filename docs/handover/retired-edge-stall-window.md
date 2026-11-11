---
workstream: retired-edge-stall-window
status: in-progress
branch: manage/retired-edge-stall-window
pr: none
plan: retired-edge-stall-window
issue: none
session: https://claude.ai/code/session_01J1YMK3Z2R5D8EtAQqikw7t
agent: opus
updated: 2026-11-11
next: ci again, then the retire commit, PR and finish
---

## Goal

A retired edge row (manager past its retire commit, running `finish`) gets a
stall clock that fits `finish` (stall + local-check minutes), and a nudge
that does not ask for a handover.

## Decisions

- A1: confirmed — `.agents/docs/consumer-repos.md` Local checks: `finish` refuses an unpushed tip and runs local-check after ci and verify, so a retired manager pushes nothing while it runs.
- A2: confirmed — `joharness.sh` dispatch edge loop: `n_edge=$((n_edge + 1))` then `elif [ "$eage" -ge "$stall" ]`, fed by `dispatch_retired_edges`.
- A3: confirmed — `JOHARNESS_LOCAL_CHECK_MINUTES|30|session|…` is a KNOBS row; `num_knob` reads it in dispatch.
- A4: confirmed — `selftest/dispatch.sh` comment above the aged case; table order kept, only the clock moves.
- The aged-edge branch's mark uses the retired-row clock too (plan-checker r8): a short `JOHARNESS_EDGE_SLOT_HOURS` would otherwise mark a manager still in `finish`.
- The retired KILL lives as its own health-table row in `orchestrator.md`, not in the ref's § KILL and LOOP (outside this plan's scope, and scoped by another plan).
- `selftest.sh` unsets `JOHARNESS_LOCAL_CHECK_MINUTES`: this session's environment sets it to 60, which would move the 75.

## Rejected

- Editing the ref's § KILL and LOOP for the retired kill: out of scope and shared with `heartbeat-read-cheaper`.

## Review

- r1: (plan-checker) existing cases forcing a retired STALL? with JOHARNESS_STALL_MINUTES=0 break under the summed window (fixed)
- r2: (plan-checker) where the retired KILL goes is unclear; the ref is out of scope (fixed)
- r3: (plan-checker) "NUDGE as above" on the IDLE/PENDING row is ambiguous once two nudges exist (fixed)
- r4: (plan-checker) acceptance "fails on origin/main" names no command or output (fixed)
- r5: (plan-checker) acceptance items state no red form (fixed)
- r6: (plan-checker) STALL? text for the 80-minute case undefined (fixed)
- r7: (plan-checker) dispatch `stall :` header goes stale for retired rows (fixed)
- r8: (plan-checker) aged-edge branch still marks at the plain window under a short slot window (fixed)
- r9: (plan-checker) the claimed 60-minute case overlaps mgr-alpha's stall case (no change)
- r10: (plan-checker) the chrsctl/gx incident is not checkable from this checkout (no change)
- r11: (plan-checker) round 2: the plan does not warn of orchestrator.md's reading budget, which the build first broke (fixed)
- r12: (plan-checker) round 2: "fails on origin/main" still names no command (fixed)
- r13: (plan-checker) round 2: a SHIPS plan's Acceptance names no consumer-side check (fixed)
- r14: (plan-checker) round 2: the verify item states no red form (fixed)
- r15: (plan-checker) round 2: A1's evidence points at a doc that does not say unpushed (fixed)
- r16: (plan-checker) round 2: Traps omit the orchestrated.md overlap with stranded-branch-plans (fixed)
- r17: (plan-checker) round 2: the chrsctl/gx incident is unverifiable here (no change)
- r18: (verifier) the aged-edge clock change has no test that fails without it (fixed: "and its mark keeps the retired-row clock: no STALL? at 60m", under JOHARNESS_EDGE_SLOT_HOURS=1)
- r19: (verifier) the new `stall :` header text is pinned by no test (fixed: "the stall header names the retired-row window beside the plain one")
- r20: (verifier) the branch rewrote its plan's aged-edge clause against the base text (no change: decided in ## Decisions, from plan-checker r8, now tested by r18)
- r21: (verifier) orchestrator-reference.md no-transport row still calls JOHARNESS_STALL_MINUTES the kill threshold, untrue for retired rows (wontfix: the ref is outside this plan and scoped by heartbeat-read-cheaper; PR body)
- r22: (verifier) the retired KILL row archives without checking whether the head moved after the interrupt (fixed: head moved = answered)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_retired_edges` — the edge scan.
