---
plan: heredoc-cpu-bound
urgency: urgent
agent: sonnet
effort: high
needs: none
requirement: none
issue: 566
scope: .agents/harness/selftest/pretool-bash-guard.sh
---

## Goal

Issue #566: the selftest case "a 20,000-line heredoc" in
`pretool-bash-guard` reds `lint` on `pull_request` runs (15 s against a
`< 15 s` wall-clock bound) while the same tree passes on `main`'s push run
and takes 0.6 s locally. It blocks every pull request's merge. The case
exists to tell a linear `strip_heredocs` (0.6 s) from the quadratic one it
replaced (67 s); wall-clock time on a shared runner under four parallel
selftest workers measures the runner's load, not the algorithm.

## Scope

- `.agents/harness/selftest/pretool-bash-guard.sh` — the heredoc case
  bounds the guard's CPU time (user + sys, bash `time` with `TIMEFORMAT`)
  instead of `$SECONDS`; same 15 s bound; the comment states what is
  measured and why.

## Out of scope

- The three other timed cases in that file (`<= 4s`): they guard the hook's
  registered 10 s wall-clock timeout, which is a wall-clock contract, and
  none of them failed in #566.
- `.agents/harness/pretool-bash-guard.sh` itself: no evidence it is slow.
- `.github/workflows/ci.yml` (core path).

## Acceptance

- `./.agents/harness/selftest.sh` — `0 failed`, the case prints
  `PASS a 20,000-line heredoc reads in <n>s of CPU`.
- With the old quadratic `strip_heredocs` substituted in a scratch copy, the
  case FAILS (the test still catches the regression it exists for).
- Under local CPU contention, the old wall-clock case reads well above the
  unloaded time while the CPU-time reading stays near it.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.

## Where to look

- `.agents/harness/selftest/pretool-bash-guard.sh:pbg` — runs the guard in a
  command substitution; `time` on the call counts that child's CPU.
- `.agents/harness/pretool-bash-guard.sh:strip_heredocs` — the linear walk.

## Traps

- Never skip, disable or quarantine the test; the bound keeps its meaning.
- Never kick CI.
