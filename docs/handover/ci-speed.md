---
workstream: ci-speed
status: in-progress
branch: manage/ci-speed
pr: none
plan: ci-speed
issue: none
session: https://claude.ai/code/session_01P1gU1UFZtCcF6w8ERTki4C
agent: opus
updated: 2026-10-23
next: Record verifier findings in ## Review

- r1: (verifier) clerk.sh's top-level unset of JOHARNESS_CLERK_* no longer protects later topics (role reds with them exported) (fixed: the runner unsets them; selftest-shards asserts every top-level topic unset is in the runner's list)
- r2: (verifier) acceptance measurements unrecorded; dispatch 5.3-5.6 s on its clone (fixed: refs_unmerged <base> and gr_docs execs cut too; measurements below)
- r3: (verifier) a fatal error in selftest.sh's inline cases printed nothing (exec capture deleted by the EXIT trap) (fixed: no capture; fail() also writes inline FAIL lines to a file the summary reads)
- r4: (verifier) a chain printed whole at its first member's place, so output order differed from the serial run (fixed: each topic prints at its own list place; selftest-shards orders a non-contiguous chain)
- r5: (verifier) the re-prime after a hook that may fetch was untested (fixed: dispatch-rescope counts merge-base execs with DRAIN_FETCH 0 and 1; red with the line deleted, measured)
- r6: (verifier) no bound on a hung unit (fixed: selftest_unit_seconds, 1800; past it the unit is a FAIL and the workers are stopped; selftest-shards case)
- r7: (verifier) missing counts file printed a shell error; orphaned unit after a worker kill may still count (fixed: redirect order; orphan counts are its real counts: no change)
- r8: (verifier) numbers without their command, dated comment in code (fixed: comment states the mechanism; numbers below name their command)
- r9: (verifier) the tree moved during review (no change: a docs-only workstream commit answering an orchestrator nudge)
- r10: (verifier) 7 behind origin/main (fixed: merged; the new orchestrated.sh lines read no other topic's state)
- r11: knobs-declared went red once in a parallel ci: printf | grep -q under pipefail dies of SIGPIPE on a >4 KB table (fixed: here-strings)
- r12: acceptance numbers, with their commands, are under `## Measurements` (no change)

## Measurements

- dispatch_freeable: `time DRAIN_FETCH=0 DISPATCH_FETCH=0 ./joharness.sh dispatch` on this repository (352 origin refs), idle, 02:42 UTC: origin/main 13.8, 14.4, 14.3 s; this branch 4.55, 4.55, 4.99 s; output `cmp` identical (two of three runs; the third differs only in one `pushed Nm` age across a minute boundary). Of the rest, 2.3 s is the two queue hooks (`drain_hook`), outside this plan.
- selftest, this branch at c7425b06 + origin/main merged, idle 4-core container, 2026-10-23:
  `time .agents/harness/selftest.sh` (default, 4 workers) `3177 passed, 0 failed`, real 4m0.5s (02:43 UTC);
  `time JOHARNESS_SELFTEST_JOBS=1 .agents/harness/selftest.sh` `3177 passed, 0 failed`, real 12m24.3s (02:47 UTC).
  The two outputs `diff` equal after temp paths are masked, except one bash-guard timing (0 s vs 1 s).
  Same container, origin/main before this branch: dispatch topic alone 420 s of a 778 s serial run (per-topic `SECONDS` around each source, 01:16 UTC).
- Bash guard time bounds (pretool-bash-guard, 4 s and 15 s), the four timed cases in each run: serial 0 0 0 1 s; parallel runs 0 0 1 1, 1 0 0 1, 0 1 0 1 s. They stay in the pool.

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_freeable` — remote-ref probe loop.
- `.agents/harness/selftest.sh` — topic loop to shard.
