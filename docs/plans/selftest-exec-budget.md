---
plan: selftest-exec-budget
urgency: normal
agent: opus
effort: high
needs: dispatch-no-merged-walks
requirement: none
issue: none
scope: shared:joharness.sh, shared:.agents/harness/selftest.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.agents/harness/selftest/clerk.sh, shared:.agents/harness/selftest/scout.sh
---

## Goal

The harness selftest is canonical's merge gate (`ci_selftest`; consumers
carry no selftest and the stage prints "not here (canonical-only)" there),
paid on every pull request here: 143 merges in the last seven days
(`git log --merges --first-parent --since=7.days --format=%h origin/main | wc -l`,
2026-10-13). Measured that day on this repository, twice, with a counting
`git` wrapper first on `PATH`: a full `bash .agents/harness/selftest.sh` took
1,149 s then 1,131 s and made 87,871 then 87,914 git execs (2,736 and 2,753
cases passed; one timing case failed both times, `80 KB of prose keywords:
exit 0, 5s (wanted <= 4s)`, in `pretool-bash-guard.sh`, which holds no git
call and is not this plan's). Where they go, from a partial
`strace -f -e trace=execve` of `./joharness.sh ci` the same day: the topics
invoke `joharness.sh` 366 times against fixture repositories, 140 of them
`dispatch`. `dispatch-no-merged-walks` makes each `dispatch` cheap; this
plan bounds the total so it cannot grow back unnoticed, and removes the
invocations that only re-run a command already run on the same state.

A fixture build cache was considered and rejected (verifier, 2026-10-13):
every topic builds ONE fixture and mutates it step by step between cases
(`dispatch.sh` creates `mgr-delta`, commits six times, pushes, asserts, and
later cases depend on that state), and every fixture stores an absolute
`remote.origin.url` under the run's temp dir, so a copied fixture pushes
into the original. There is no "build" a per-case copy could restore.

## Scope

- `joharness.sh` — `ci_selftest` counts the selftest's git execs from
  OUTSIDE the selftest: a wrapper `git` first on `PATH` for the selftest run
  (a script that appends one line to a file under the run's temp dir and
  `exec`s the real git — the method that counted 87,871 and 87,914), then
  prints `selftest git execs: <n> (budget <JOHARNESS_SELFTEST_GIT_BUDGET>)`
  and reds the stage above the budget. Default `90000`: a written number
  just above today's count, so the stage is green on `origin/main` and red
  once the count grows by about two percent; the pull request that lands
  this plan replaces it with the counted number after the merges below plus
  a tenth. The knob is `session`-scoped (a canonical-only stage), joins the
  env scrub list in `selftest.sh`, and gets its `KNOBS` row if
  `knobs-declared-once` has landed.
- `.agents/harness/selftest/dispatch.sh`, `clerk.sh`, `scout.sh` — the
  three topics with the most `joharness.sh` invocations: where consecutive
  cases run the same command on the same fixture state to assert different
  lines, one invocation feeds several `expect`s. Assertions are kept one for
  one; a case that changes the fixture between two runs keeps both runs.
  Count the invocations before and after (`grep -c 'joharness.sh' <topic>`)
  and quote them.

## Out of scope

- Removing or weakening any case or assertion.
- A fixture cache (rejected above).
- The failing timing case: its own issue, not this plan's.
- `shellcheck`, the glossary and graph lints: a minority of `ci`'s execs.
- Parallelising the selftest: a later plan once the count is bounded.
- Anything a consumer runs: the selftest ships to none.

## Acceptance

- `time bash .agents/harness/selftest.sh` before and after, on this
  repository, in the pull request (`bash`'s `time` keyword; this environment
  has no `/usr/bin/time`).
- `bash .agents/harness/selftest.sh` — every existing case passes;
  `./joharness.sh ci` — `ci: pass`, printing `selftest git execs: <n>` with
  `n` under the budget; quote the line.
- Test for the fix must FAIL without it: `JOHARNESS_SELFTEST_GIT_BUDGET=1000
  ./joharness.sh ci` — the stage is red, naming the count and the budget;
  quote the line.
- Plan `ci` calls SHIPS (`joharness.sh` syncs): the consumer check is
  `./joharness.sh ci` on gx still printing the stage's "not here
  (canonical-only)" line; the wrapper only runs when a selftest is present.

## Where to look

- `joharness.sh:ci_selftest` — the stage that runs the selftest and skips
  when it is absent.
- `.agents/harness/selftest.sh` — the `unset` scrub list at the top,
  `SELFTEST_TOPICS`, the fixture helpers (`remote add origin "${TMP}/…"`).
- `.agents/harness/selftest/dispatch.sh` — the heaviest topic; its
  `mgr-delta` sequence shows why a cache does not fit.
- `.agents/harness/pretool-bash-guard.sh` — the perf doctrine ("NO FORKS",
  a row budgeted at 0 external commands) the budget copies.
- `.agents/harness/selftest/feedback.sh` — an existing perf measurement
  (`PERF_EDGES`) and how it reports counts.

## Traps

- Never skip, disable or quarantine a case to get the count down.
- Never `pgrep -f` a pattern your own command line carries: the wrapper
  counts by appending, not by scanning processes.
- A background command must be able to finish: bound the timing runs.
- Trust counted numbers: the first default is written just above the
  count; the pull request replaces it with the counted one.
- `knobs-declared-once` adds the `KNOBS` table: whichever lands second adds
  this knob's row.
