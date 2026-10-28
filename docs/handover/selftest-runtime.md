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
next: Finish JOBS=1 measurement, time dispatch sections, write Findings into docs/research/selftest-runtime.md
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

## Rejected

- None yet.

## Review

- Pending.

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — runner, `SELFTEST_CHAINS`, jobs.
