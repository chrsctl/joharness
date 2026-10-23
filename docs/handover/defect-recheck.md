---
workstream: defect-recheck
status: in-progress
branch: claude/defect-recheck
pr: none
plan: defect-recheck
issue: none
session: https://claude.ai/code/session_01MQumdxosGQZZvBDND5TrvK
agent: opus
updated: 2026-10-23
next: Run ci and verify, then verifier review, then finish
---

## Goal

A manager parked on `defect: #<n>` re-checks once the base moved after the
block, so a defect fixed with no plan resumes within hours, not after the
48h UNPLANNED human ping.

## Decisions

- A1: confirmed — the run walk in `dispatch_defect_state` stops at a commit
  whose `next:` differs; the orchestrator's `Recheck:` `next:` commit (§
  Resume mechanics) is that commit, so the re-park is a new block commit.
  A re-park with no orchestrator write would not restart it.
- A2: refuted — `--since` is the walk the function rejects (stops at the
  first older-dated commit). Used: first-parent `origin/main ^<block>`, any
  `%ct` >= the block's, the retire walk's own rule.
- RECHECK rides RESUME's machinery: one slot, capped, scope held, never
  DRAINED. Slots/verdict label reads `RESUME`, `RECHECK` or
  `RESUME/RECHECK` by what is present, so existing RESUME text is unchanged.
- STUCK and UNPLANNED age from the FIRST park on #<n> on the branch, back
  to the last orchestrator `Resume:` (plan-checker r1, verifier r12), and
  OUTRANK RECHECK (verifier r9): rechecks run inside the first
  JOHARNESS_DEFECT_PLAN_HOURS, then the human hears once. Plan amended
  (it ranked RECHECK before them); flag for human in the PR.
- RESUME rows take slots before RECHECK rows; rows print in their own
  order (each `fx_rows` entry carries the text before it, reordering
  would glue lines).

## Rejected

## Review

- r1: (plan-checker) re-park resets STUCK/UNPLANNED clocks, human never told (fixed)
- r2: (plan-checker) negative acceptance cases cannot fail on origin/main (fixed: plan says which must)
- r3: (plan-checker) A1 holds only via the orchestrator's Recheck commit (no change: recorded in Decisions)
- r4: (plan-checker) A2 proposes `--since`, which the function rejects (fixed: ^block walk)
- r5: (plan-checker) slot, verdict, scope-held and orchestrate.md respawn exception unspecified (fixed: Decisions, orchestrate.md)
- r6: (plan-checker) "0 lifts it" reads as no wait (no change: repo convention, = off)
- r7: (plan-checker) acceptance cases are prose, not commands (no change: selftest cases are the commands)
- r8: (plan-checker) Goal omits the planned-but-fixed-elsewhere case (wontfix: RECHECK requires no plan names #n by plan design)
- r9: (verifier) RECHECK ranked before STUCK/UNPLANNED still hid them on a base moving faster than the recheck clock; unbounded respawns (fixed: STUCK/UNPLANNED outrank RECHECK, selftest cases)
- r10: (verifier) Resume mechanics drop notified=, so the human was told once per recheck cycle (fixed: by r9, RECHECK never follows UNPLANNED/STUCK while the first park stands)
- r11: (verifier) scope flipped released/held between UNPLANNED and RECHECK passes (fixed: by r9, no RECHECK after them)
- r12: (verifier) first-park walk spanned a park an earlier RESUME closed (fixed: walk stops at the orchestrator's `Resume:` next:, selftest case); empty merge base widens it (no change: same as the existing run walk)
- r13: (verifier) a RECHECK row could take the only slot ahead of a RESUME; label counted all rows (fixed: RESUME ranks first, label from slotted rows, selftest cases)
- r14: (verifier) knob rows for PLAN/FIX hours still said "after a defect: block" (fixed)
- r15: (verifier) STUCK first-park clock untested (fixed: selftest case)
- r16: (verifier) live-branch plan, waits-for-slot, 0-slot verdict, mixed label untested (fixed: selftest cases; scope-held reuses RESUME's path, no new case)
- r17: (verifier) re-park case decided by base, not age gate (no change: that is the A1 property)
- r18: (verifier) a manager can self-schedule respawns via an unplanned defect: park (no change: bounded by r9 to JOHARNESS_DEFECT_PLAN_HOURS, then the human hears)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_defect_state` — the state reader.
