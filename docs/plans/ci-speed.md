---
plan: ci-speed
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, shared:.agents/harness/selftest.sh, .agents/harness/selftest/dispatch.sh
---

## Goal

The owner asked (session 2026-10-23) to speed up `ci`. Measured that day on
a 4-core cloud container at origin/main: the full selftest takes 650 s and
runs 63 topics one after another; the `dispatch` topic alone takes 353 s
(54%), and the next three (`scout` 42 s, `bootstrap-consumer` 37 s,
`janitor` 22 s) take 100 s. Every manager pays it once locally and once on
GitHub per code PR. Separately, one real `./joharness.sh dispatch` on this
repository takes 11.5 s, 7 s of it in `dispatch_freeable` probing all 348
remote refs. Target: full selftest under 300 s on the same container, and
real `dispatch` under 5 s, with the exact same pass count.

## Scope

1. **`joharness.sh:dispatch_freeable`.** The loop that calls
   `free_claimed_ever` iterates every remote ref
   (`for-each-ref refs/remotes/origin`). For a ref merged into the base
   branch the range `base..ref` is empty and the function returns 1, so
   restrict that loop to refs not merged into
   `refs/remotes/origin/<base>` (reuse `refs_unmerged` if it fits). The
   result must be identical; only the work shrinks.
2. **Parallel topic shards in `.agents/harness/selftest.sh`.** Today the
   runner sources every topic in one shell, and its header says a topic may
   read state an earlier topic built. Research first:
   - Find every cross-topic dependency: a topic reading a variable,
     function, file or fixture another topic defined.
   - Record them in the workstream file's Decisions.
   Then run the topics in `JOHARNESS_SELFTEST_JOBS` parallel groups (default:
   `nproc`, capped at 4). Each group is a subshell with the runner's helpers
   and its own `TMP`. Dependent topics stay in one group, in their current
   order. Merge the PASS/FAIL/SKIP counts and print the FAIL lines grouped
   by topic. `JOHARNESS_SELFTEST_JOBS=1` must reproduce today's serial run.
   The git-exec budget (`selftest_counted`) still counts every topic.
3. **`selftest/dispatch.sh` fixtures.** Where cases rebuild the same scratch
   repository, build it once and copy it (`cp -a`) per case. Never weaken
   an assertion.
- Add `JOHARNESS_SELFTEST_JOBS` to the KNOBS table (`knobs-declared` selftest
  must pass).

## Out of scope

- Running only some topics locally, or changing what GitHub runs: `ci` runs
  the same suite in both places.
- `.github/workflows/ci.yml` (core path).
- Rewriting topics beyond what isolation or fixture reuse needs.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `JOHARNESS_SELFTEST_JOBS=1 .agents/harness/selftest.sh` and the default
  run print the same `N passed, 0 failed` (same N); record both counts and
  both wall times (`time`) in `## Review`.
- Default run under 300 s on a 4-core container (measured command and date
  in `## Review`).
- `time DRAIN_FETCH=0 DISPATCH_FETCH=0 ./joharness.sh dispatch` on this
  repository under 5 s, and its output byte-identical to the output before
  the change (diff in `## Review`).
- A test proving shards are independent: one topic made to fail in a
  parallel run still reports exactly that topic's FAIL line and a non-zero
  exit.
- Plan `ci` calls SHIPS: the runner and topics reach every consumer.

## Where to look

- `joharness.sh:dispatch_freeable`, `free_claimed_ever`, `refs_unmerged`.
- `.agents/harness/selftest.sh`: `SELFTEST_TOPICS`, the topic `for` loop, the
  duplicate-function check, the summary; `joharness.sh:selftest_counted`.
- `.agents/harness/selftest/dispatch.sh`: `dsp`, `two`, `rb`, `ms`, `dr`
  fixtures (95 calls, 361 commit/push lines).

## Traps

- Fail closed: a group that crashes or times out is a FAIL, never a missing
  count.
- NEVER skip, disable or quarantine a test; the pass count must not drop.
- Tests that measure time (the bash guard's 4 s bounds) run slower under
  load. A parallel run must not make them flaky: keep them in a group that
  runs alone, or say how you proved them stable.
- No core paths.
