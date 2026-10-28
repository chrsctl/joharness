---
workstream: selftest-runtime
status: in-progress
branch: manage/selftest-runtime
pr: none
plan: selftest-runtime
issue: none
session: https://claude.ai/code/session_01J1YMK4HBTEEyzrJd3aEM1B
agent: opus
updated: 2026-10-28
next: Second-context verification of Findings, then graduate into selftest.sh header and delete the research file
---

## Goal

Settle research `selftest-runtime`: where the ~493 s of the selftest go, and
which changes cut it most without dropping a case's fail-without-the-fix
property. Graduate to `.agents/harness/selftest.sh` header.

## Decisions

- Measure in a scratch worktree with an uncommitted timing patch to the
  runner (ST_TIMING per topic, ST_GITLOG git shim), never on the branch.
- First run (4 CPUs, jobs 4): 406 s wall, topic sum 1254 s; dispatch 362 s
  is the critical path (start 38 s, end 401 s); 86.5k git execs, dispatch
  29.5k. dispatch.sh splits clean at line 1096 (dspwork vs dfwork).
- jobs 1: 996 s wall, sum 988 s. A fixture dispatch call costs ~0.45 s per
  claim branch (dfx: 4 branches 1.3 s, 19 branches 8.7 s). release.sh
  splits clean at line 771 (jwork vs hwork). Scratch run with both splits
  and longest-first claim order running (scratchpad run2.sh).

## Rejected

- None yet.

## Review

- Pending.

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — runner, `SELFTEST_CHAINS`, jobs.
