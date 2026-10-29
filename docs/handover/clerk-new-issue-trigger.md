---
workstream: clerk-new-issue-trigger
status: in-progress
branch: clerk-new-issue-trigger
pr: none
plan: clerk-new-issue-trigger
issue: none
session: https://claude.ai/code/session_01J1YMK5uhS1o6RkivUJMsPa
agent: opus
updated: 2026-10-29
next: Plan-checker round 2, then build clerk_last_read and the cmd_clerk lines
---

## Goal

A new open GitHub issue starts the clerk ahead of the 24h cadence: the
orchestrator reads issues, `./joharness.sh clerk` supplies `last read` and
`issue wait`.

## Decisions

- A1, A2, A4, A5: confirmed (plan-checker read the cited lines). A3: refuted as written — the computation lives in clerk_park_early; plan fixed.

## Rejected

- None yet.

## Review

- r1: (plan-checker) "landed = first commit" contradicts clerk_park_early, which moves both records back by the knob (fixed: plan says both, helper clerk_last_read; orchestrated.md row corrected)
- r2: (plan-checker) knob 0 read two ways (fixed: 0 switches the trigger off, `issue wait: off`)
- r3: (plan-checker) computation sits inline behind clerk_park_early's early returns (fixed: plan names the extracted helper, knob 0 = no shift)
- r4: (plan-checker) a skipped issue re-fires each run (wontfix: fires again only when the defect knob exceeds the issue wait plus the pass's length; defaults never; named in Out of scope)
- r5: (plan-checker) a new issue behind a full batch is never reached by the early clerk (wontfix: the batch order is clerk.md's and the human's knob; named in Out of scope)
- r6: (plan-checker) scout exclusion misses titles starting `scout:` (fixed)
- r7: (plan-checker) Traps claims a conf-keys entry is needed (fixed: dispatch keys need none)
- r8: (plan-checker) Acceptance items name no command (fixed: the selftest topic, `0 failed`)
- r9: (plan-checker) defect-trigger equality cannot be asserted from output (fixed: one helper; dispatch-park cases pin the defect side)
- r10: (plan-checker) SHIPS line not runnable here (fixed: the fixture is a consumer copy of joharness.sh)
- r11: (plan-checker) placement under the unreadable cadence unstated (fixed: both lines print on every path)
- r12: (plan-checker) A3 cites clerk_due, not clerk_park_early (fixed)
- r13: (plan-checker) overlap with role-on-demand, retro-event-triggers undeclared (no change: shared: scope, whichever lands later merges origin/main)

## Blockers

None.

## Where to look

- `joharness.sh:clerk_due` — the one "last read" computation to reuse.
