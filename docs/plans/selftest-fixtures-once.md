---
plan: selftest-fixtures-once
urgency: normal
agent: opus
effort: high
needs: refs-snapshot-once
requirement: none
issue: none
scope: shared:.agents/harness/selftest.sh, shared:.agents/harness/selftest/dispatch.sh, shared:.agents/harness/selftest/clerk.sh, shared:.agents/harness/selftest/scout.sh, .agents/harness/selftest/ci-exec-budget.sh
---

## Goal

`./joharness.sh ci` on gx spawned 42,135 processes and 13,902 git calls
before its strace was stopped at about twelve minutes (2026-10-13,
`strace -f -e trace=execve`). The paths say where: `-C /tmp/tmp.*/dispatchwork`
and `-C /tmp/tmp.*/reviewwork` — the harness selftest building fixture
repositories (435 `fetch`, 324 `commit`) and invoking `joharness.sh` 366
times against them, 140 of them `dispatch`. Beside git: 7816 `bash`, 5495
`awk`, 4442 `grep`, 2320 `sort`, 2061 `sed`. `ci` is the merge gate every
branch runs, so its cost is paid per pull request. `refs-snapshot-once`
makes each `dispatch` cheap; this plan stops building the same fixture
repeatedly and bounds the total so it cannot grow back unnoticed.

## Scope

- `.agents/harness/selftest.sh` — fixture helpers gain a per-run cache: a
  fixture built from the same recipe (the sequence of commits, branches and
  files a case asks for) is built once under the run's temp dir and cloned
  (`git clone --shared`) for each case that does not mutate it; a case that
  mutates declares so and gets a fresh clone. Cases keep their text; only
  the helper changes.
- `.agents/harness/selftest/dispatch.sh`, `clerk.sh`, `scout.sh` — the
  three parts with the most `joharness.sh` invocations: cases that run the
  same command on the same fixture to assert different lines are merged to
  one invocation with several `expect`s, where the assertions are
  independent.
- `.agents/harness/selftest/ci-exec-budget.sh` — counts the git execs of a
  full `bash .agents/harness/selftest.sh` run (strace when present, else
  `GIT_TRACE=1` lines) against a written bound of 5,000, printing the
  count; `skip` with the reason when neither counter exists. The bound is
  taken from the measurement above and the pull request records the count
  after this plan.

## Out of scope

- Removing or weakening any case. Fewer processes, same assertions.
- `shellcheck`, the glossary and graph lints: measured as a minority of
  `ci`'s execs.
- Parallelising the selftest: a later plan once the count is bounded.

## Acceptance

- `time bash .agents/harness/selftest.sh` before and after, on this
  repository and on gx, in the pull request.
- `bash .agents/harness/selftest.sh` — every existing case passes;
  `ci-exec-budget.sh` prints the counted git execs under 5,000;
  `./joharness.sh ci` — `ci: pass`.
- Test for the fix must FAIL without it: with the cache disabled by env
  (`JOHARNESS_SELFTEST_NOCACHE=1`, read only by the helper), the budget
  case goes red; quote the two counts.
- Plan `ci` calls SHIPS (`.agents/harness` syncs): the consumer check is
  `./joharness.sh ci` wall clock on gx after sync.

## Where to look

- `.agents/harness/selftest.sh` — the fixture helpers and the `git ls-files
  -- '.agents/harness/selftest/*.sh'` discovery of parts.
- `.agents/harness/selftest/dispatch.sh` — the heaviest part; its fixture
  recipes.
- `.agents/harness/pretool-bash-guard.sh` — the perf doctrine ("NO FORKS",
  a row budgeted at 0 external commands) this plan's budget case copies.
- `.agents/harness/selftest/feedback.sh` — an existing perf measurement
  (`PERF_EDGES`) and how it reports counts.

## Traps

- Never skip, disable or quarantine a case to get the count down.
- A shared clone must never be mutated by a case that did not declare it:
  the cache helper refuses a write to a shared fixture (a `chmod -R a-w` or
  a guard commit hash check), so a silent mutation fails loudly.
- Trust counted numbers: the bound is written; the case prints the count.
