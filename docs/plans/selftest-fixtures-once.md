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

`./joharness.sh ci` on THIS repository spawned 42,135 processes and 13,902
git calls before its trace was stopped at about twelve minutes
(2026-10-13, `strace -f -e trace=execve`; strace slows an exec-heavy run,
so the counts are the number, not the wall clock). The paths say where:
`-C /tmp/tmp.*/dispatchwork` and `-C /tmp/tmp.*/reviewwork` — the harness
selftest (`.agents/harness/selftest.sh`, 685 lines plus 60 topic files)
building fixture repositories (435 `fetch`, 324 `commit`) and invoking
`joharness.sh` 366 times against them, 140 of them `dispatch`. Beside git:
7,816 `bash`, 5,495 `awk`, 4,442 `grep`, 2,320 `sort`, 2,061 `sed`. The
selftest is canonical-only (consumers carry none; `ci_selftest` skips when
the file is absent), so this is canonical's merge gate, paid per pull
request here: 139 merges in the last seven days. `dispatch-no-merged-walks`
makes each `dispatch` cheap; this plan stops building the same fixture
repeatedly and bounds the total so it cannot grow back unnoticed.

## Scope

- `.agents/harness/selftest.sh` — fixture helpers gain a per-run cache: a
  fixture built from the same recipe (the sequence of commits, branches and
  files a case asks for, hashed) is built once under the run's temp dir and
  cloned (`git clone --shared`) for each case that reads it; a case that
  mutates its fixture says so in the helper call and gets a fresh clone.
  Mutation of a shared fixture is detected, not prevented: the helper
  records `git rev-parse --all | sha1sum` and the working-tree status at
  hand-out and compares at the case's end; a difference fails that case
  by name (a `chmod` guard would not hold: the selftest runs as root in
  CI). `JOHARNESS_SELFTEST_NOCACHE=1` disables the cache for the
  fail-without-it measurement; it joins the env scrub list.
- `.agents/harness/selftest/dispatch.sh`, `clerk.sh`, `scout.sh` — the
  three topics with the most `joharness.sh` invocations: where several
  cases run the same command on the same fixture to assert different lines,
  one invocation feeds several `expect`s. Assertions are kept one for one.
- `joharness.sh` — `ci_selftest` counts the selftest's git execs from
  OUTSIDE the selftest: it puts a wrapper `git` first on `PATH` for the
  selftest run (a script that appends one line to a file under the run's
  temp dir and `exec`s the real git), then prints
  `selftest git execs: <n> (budget <JOHARNESS_SELFTEST_GIT_BUDGET>)` and reds
  the stage above the budget. Default `5000`, a written number taken from
  the 13,902 partial count; the pull request records the counted number
  after this plan and resets the default to the counted number plus a
  tenth, so the bound is counted, not guessed. The budget knob is a
  `session`-scoped knob (canonical-only stage). Counting from inside the
  selftest would source the topic that counts and recurse; counting with
  `GIT_TRACE` would see nothing, since every git call in `joharness.sh`
  carries `2>/dev/null`.

## Out of scope

- Removing or weakening any case or assertion. Fewer processes, same
  assertions.
- `shellcheck`, the glossary and graph lints: a minority of `ci`'s execs.
- Parallelising the selftest: a later plan once the count is bounded.
- Anything a consumer runs: the selftest ships to none.

## Acceptance

- `time bash .agents/harness/selftest.sh` before and after, on this
  repository, in the pull request (`bash`'s `time` keyword, not
  `/usr/bin/time`, which this environment lacks).
- `bash .agents/harness/selftest.sh` — every existing case passes;
  `./joharness.sh ci` — `ci: pass`, printing `selftest git execs: <n>` with
  `n` under the budget; quote the line.
- Test for the fix must FAIL without it: `JOHARNESS_SELFTEST_NOCACHE=1
  ./joharness.sh ci` — the stage is red on the budget; quote both counts.
- A deliberate mutation of a shared fixture inside one case (made and
  reverted in the pull request) fails that case by name; quote the line.
- Plan `ci` calls: canonical-only (`ci`'s ship-scope stage says so); the
  check is this repository's own `ci`.

## Where to look

- `.agents/harness/selftest.sh` — the fixture helpers, `SELFTEST_TOPICS`,
  the env scrub list, and the `git ls-files` discovery of topics.
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
- Trust counted numbers: the first default is written; the pull request
  replaces it with the counted one.
