---
workstream: finish-catch-up
status: in-progress
branch: claude/finish-catch-up
pr: none
plan: finish-catch-up
issue: none
session: https://claude.ai/code/session_01J1YMK5e4qFM7qu8dpzkfv1
agent: opus
updated: 2026-11-10
next: Run the verifier at opus on the branch diff, record findings, then ci, finish, PR
---

## Goal

gx PR #1417: a local-mode finish (~27 min) can never win the race to 0
behind on a busy base; the manager gave up leaving a green non-draft PR,
merged 172 stale by a human, main went red. Fix the starvation (catch-up
certification) and the exit (draft + `conflict:` block).

## Decisions

- A1: confirmed — checks_gate returns before ci on BEHIND.
- A2: confirmed — git 2.43 here; merge-tree failure falls to the full run.
- A3: confirmed — `rev-parse --absolute-git-dir`, file outside the tree.
- A4: confirmed — `block_reason_ok` lists `conflict:`; orchestrator notifies on blocked.
- Catch-up never rewrites the certificate: every catch-up measures from one
  full run, so chained catch-ups cannot drift from what local-check saw.
- Same-session plan (`.agents/docs/plans.md`, Lifecycle): the task arrived
  as a direct ask; plan lives on this branch, deleted at retire.

## Rejected

- Orchestrator-granted merge slot: new state, and still 27 min per slot.

## Review

- r1: (plan-checker) acceptance "fails with change reverted" not runnable (fixed: stash command and expected FAIL line)
- r2: (plan-checker) ci/verify acceptance gives no failure shape or count (fixed: last line, 17 PASS catch-up cases)
- r3: (plan-checker) SHIPS plan names no consumer-side check (fixed: Acceptance consumer line)
- r4: (plan-checker) scope overlaps human-answers-on-github.md, no needs: (no change: neither reads the other's result; reconcile merge, noted in Traps)
- r5: (plan-checker) knob "registered in num_knob" wrong; scope class unstated (fixed: one KNOBS row, scope session)
- r6: (plan-checker) conflict: defined as "does not resolve clean", starved merge resolves clean (fixed: manager.md §3 definition widened)
- r7: (plan-checker) "behind by at most" ambiguous (fixed: <certified base>..origin/main)
- r8: (plan-checker) merge-tree of which two unstated (fixed: certified head and origin/main)
- r9: (plan-checker) "both sides" unstated (fixed: ranges named)
- r10: (plan-checker) refusal case count ambiguous (fixed: four refusal cases listed)
- r11: (plan-checker) Goal says ci only, Scope keeps verify (fixed: Goal names verify when needed)
- r12: (plan-checker) git 2.38 floor not declared anywhere (fixed: A2 says no floor, older git fails closed to full run)
- r13: (plan-checker) gx facts unverified here (no change: a consumer's reading, marked WEAK in manager-reference.md)

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — certificate and catch-up.
