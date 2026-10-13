---
plan: selftest-fixtures-once
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
paid on every pull request here: 140 merges in the last seven days
(`git log --merges --first-parent --since=7.days --format=%h origin/main | wc -l`,
2026-10-13). Measured that day on this repository with a counting wrapper
first on `PATH`: a full `bash .agents/harness/selftest.sh` took 1,149 s and
made 87,871 git execs (2,736 cases passed, one timing case failed:
`80 KB of prose keywords: exit 0, 5s (wanted <= 4s)`, unrelated to this
plan). A partial `strace -f -e trace=execve` of `./joharness.sh ci` the same
day showed where they go: `-C /tmp/tmp.*/dispatchwork` and
`-C /tmp/tmp.*/reviewwork` — the topics building fixture repositories (435
`fetch`, 324 `commit` in the first twelve minutes) and invoking
`joharness.sh` 366 times against them, 140 of them `dispatch`.
`dispatch-no-merged-walks` makes each `dispatch` cheap; this plan stops
building the same fixture repeatedly and bounds the total so it cannot grow
back unnoticed.

## Scope

- `.agents/harness/selftest.sh` — fixture helpers gain a per-run build
  cache: a fixture built from the same recipe (the sequence of commits,
  branches and files a topic asks for, hashed) is built once under the
  run's temp dir, and every case that asks for it gets a PRIVATE copy made
  with `cp -a` of the whole fixture directory — remote and work repository
  alike — so remote-tracking refs, `origin` URLs and every ref a case
  reads are what the build produced (a `git clone --shared` drops
  remote-tracking refs with no local branch and points `origin` at the
  cache, measured 2026-10-13, so it is not the copy). A case may mutate its
  copy freely; the cache is never handed out itself. The switch for the
  fail-without-it measurement is an argument, not an environment variable:
  `bash .agents/harness/selftest.sh --no-fixture-cache`, parsed before the
  `unset JOHARNESS_…` scrub at the top (which would erase an env switch).
- `.agents/harness/selftest/dispatch.sh`, `clerk.sh`, `scout.sh` — the
  three topics with the most `joharness.sh` invocations: where several
  cases run the same command on the same fixture to assert different lines,
  one invocation feeds several `expect`s. Assertions are kept one for one.
- `joharness.sh` — `ci_selftest` counts the selftest's git execs from
  OUTSIDE the selftest: a wrapper `git` first on `PATH` for the selftest run
  (a script that appends one line to a file under the run's temp dir and
  `exec`s the real git — the method that counted 87,871), then prints
  `selftest git execs: <n> (budget <JOHARNESS_SELFTEST_GIT_BUDGET>)` and reds
  the stage above the budget. Default `90000`: a written number set just
  above today's count, so the stage is green on `origin/main` and red the
  first time the count grows; the pull request that lands this plan
  replaces it with the counted number after the cache plus a tenth. The
  knob is `session`-scoped (a canonical-only stage) and joins the env scrub
  list; if `knobs-declared-once` has landed it also gets its `KNOBS` row.
  `ci_selftest` passes `--no-fixture-cache` through when
  `JOHARNESS_SELFTEST_NOCACHE=1` is set, for the measurement below.

## Out of scope

- Removing or weakening any case or assertion. Fewer processes, same
  assertions.
- The failing timing case above: its own issue, not this plan's.
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
- Test for the fix must FAIL without it: `JOHARNESS_SELFTEST_NOCACHE=1
  ./joharness.sh ci` with the post-plan budget — the stage is red; quote
  both counts.
- Plan `ci` calls SHIPS (`joharness.sh` syncs): the consumer check is
  `./joharness.sh ci` on gx still printing the stage's "not here
  (canonical-only)" line, since the wrapper only runs when a selftest is
  present.

## Where to look

- `.agents/harness/selftest.sh` — the fixture helpers, the `unset` scrub
  list at the top, `SELFTEST_TOPICS`, and the `git ls-files` discovery of
  topics.
- `.agents/harness/selftest/dispatch.sh` — the heaviest topic; its fixture
  recipes (`dispatchwork`).
- `.agents/harness/selftest/review.sh` — `reviewwork`.
- `joharness.sh:ci_selftest` — the stage that runs the selftest and skips
  when it is absent.
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
