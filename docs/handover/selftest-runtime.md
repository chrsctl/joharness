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
next: Fill F4 with run 9, write Verification, re-verify, delete research file, merge origin/main, finish
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
  and heavy-first claim order measured (runs 6, 9 in the research file).

## Rejected

- None yet.

## Review

- r1: (verifier) spawn prompt carried method summary and focus, no merge base sha (no change: noted; the verifier judged the diff without it, next spawn follows subagents.md)
- r2: (verifier) plan names a claim order never measured: prototype claimed ST_FIRST units in list order (fixed: plan and Method say list order, the measured one)
- r3: (verifier) 1322 programs counts resumed and failed execve lines (fixed: 1116 successful, 617 non-git, in F2 and plan 2)
- r4: (verifier) Sweep unmet: six top-80% topics without cause (fixed: F6 names each cause and a proposed change with estimate)
- r5: (verifier) 0.45 s per claim branch generalised from dfx alone, and counts refs (fixed: 0.15 dsp to 0.42 dfx per origin ref, header and F2)
- r6: (verifier) 177 of 277 and 250 of 277 mix runs (fixed: 177 of 321 in run 4; 250 s named as run 5 beside run 3's 277)
- r7: (verifier) header says dispatch held the run alone 362 s (fixed: ran 362, alone the last 98)
- r8: (verifier) header states an estimate as measured, 180 git init (fixed: estimated, 145)
- r9: (verifier) graduated numbers cannot be re-taken: patch and simulation unsaved (fixed: both verbatim in Method, header points at the file history)
- r10: (verifier) research file deleted before Verification ran (fixed: restored, Verification filled, deleted in the last commit)
- r11: (verifier) a research diff may not add plans (wontfix: manage.md section 2 puts follow-up work in this PR as plan files; precedent 68d06480)
- r12: (verifier) plan 2 byte-identical dispatch output fails on clock ages (fixed: back to back, ages masked by a named sed)
- r13: (verifier) plan 2 acceptance counts git execs, goal is time (fixed: seconds per dfx call at most 0.5x, exec count beside)
- r14: (verifier) plan 2 needs: plan 1 reads no result, breaks the dfx anchor (fixed: needs none, anchor dsp)
- r15: (verifier) plan 2 scope has no room for its cache trap's test (fixed: dispatch.sh in scope, case named)
- r16: (verifier) plan 1 silent on selftest-shards fixture, no order case, no threshold, one FATAL half tested (fixed: names ignored per run, shards case, 0.9x on n=2, both halves)
- r17: (verifier) -19.5% from one sample per arm (fixed: run 9, n=2 alternating on a quiet box, in F4)
- r18: (verifier) run 7 was the scratch worktree, wall is date difference, review counted a placeholder, branch behind main (fixed: Method says so; placeholder gone; main merged before finish)

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — runner, `SELFTEST_CHAINS`, jobs.
