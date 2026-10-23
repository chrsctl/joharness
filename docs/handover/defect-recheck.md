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
- STUCK and UNPLANNED age from the FIRST park on #<n> on the branch
  (plan-checker r1): without it every re-park resets them and the human is
  never told. Plan amended; flag for human in the PR.

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

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_defect_state` — the state reader.
