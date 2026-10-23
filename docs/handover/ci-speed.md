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
next: Measure JOBS=1 vs default counts and times; dispatch timing; review
---

## Goal

Owner asked to speed up `ci`: full selftest under 300 s on a 4-core
container (650 s at origin/main), real `dispatch` under 5 s, same pass count.

## Decisions

- Cross-topic dependencies (static scan of every topic for variables,
  functions and `${TMP}` paths another topic defines, then read by hand):
  `$work` (runner fixture) read in order by handover-context,
  -with-a-fork-remote, -churn-line, -issue-claim, -review-line, queue-context,
  -scope-waves, -fanout, session-start; `$cwork`/`ci_rc` ci-churn ->
  ci-canonical-only-selftest; `$lwork`/`lint_ci`/`lint_section`
  ci-graph-lint -> clerk; `$syncsrc`/`$syncdst`/`sync` sync-to-consumer ->
  sync-layer-only. No topic cds, exports, traps or writes under ROOT at top
  level; no topic reads `$out`/`$rc` before setting it. These four are
  `SELFTEST_CHAINS`; a fatal check keeps them listed and in list order.
- Units (a chain, or one topic) each run in a subshell with its own TMP;
  workers claim units in list order by `mkdir`; output printed in list
  order, so JOBS=1 and JOBS=4 print the same text. A unit with no counts
  file = FAIL (fail closed).
- dispatch.sh (420 s of 773 s serial here) is one long topic: split at its
  fixture boundaries into dispatch, -rescope, -curate, -order,
  -branch-plans (pure line moves; merged-filter section rides with its ms
  fixture, unreadable-hook section with dsp). Without it no sharding gets
  under 300 s.
- dispatch_done_evidence memoizes each blob's verdict per process: the
  same `git show` + awk ran once per branch walk (441 shows on one fixture
  dispatch).
- Merge bases with the base branch primed once per `dispatch` (mb_prime,
  base_mb): 107 merge-base execs for 16 distinct pairs were 2.2 s of 6.9 s.
  Re-primed after the hooks when DRAIN_FETCH lets them fetch.
- Plan item 3 (cp -a fixture reuse): nothing to reuse. Each of the 16
  dispatch fixtures is built once (two `git init` each), never per case; the
  topic's time is its ~95 `dispatch` calls (3.7 s each in the block-reason
  cases), which the two memos above shrink.
- Bash guard's time-bounded cases (pretool-bash-guard, bounds 4 s and 15 s)
  stay in the pool: read 0-1 s in every parallel run (par1, par2, par3) vs
  0-1 s serial.

## Rejected

- None yet.

## Review

- r0: placeholder until review runs (no change)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_freeable` — remote-ref probe loop.
- `.agents/harness/selftest.sh` — topic loop to shard.
