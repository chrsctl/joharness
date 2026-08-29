---
plan: guard-perf-budget
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh, .agents/harness/handover-guard.sh, .agents/harness/selftest.sh
---

## Goal

`handover-guard.sh` runs on every Stop, and nothing budgets it. It is absent
from `joharness.sh:perf_rows`, which covers `feedback`, `review`, `graph`,
`session-start` and `queue-context` — every entrypoint a session pays for
except the one that fires most often.

The unsupervised-boundary work (issue #114) made that worse and is what
surfaced it. The guard now forks `joharness.sh` twice per Stop — once for
`mode`, once for `protocol-paths` — and runs up to four git commands per
listed path. Six paths, so up to 24 git invocations plus two entrypoint
forks, where before it ran four git commands against one hardcoded prefix.
Recorded as `r16 (open, wontfix here)` on that branch's workstream file: real,
but changing when the guard fires was explicitly out of that plan's scope.

Count it before deciding anything. The number may be fine — a Stop hook that
costs 26 forks once per turn is not obviously a problem — and this repo's own
rule is that a budget is a ceiling for a regression in kind, not a target to
optimise toward.

## Scope

- `joharness.sh` — a `perf_rows` entry for the guard, with a budget set from
  a counted number, recorded in the same commit.
- `.agents/harness/handover-guard.sh` — only if the count justifies it. The
  two obvious reductions: one entrypoint fork instead of two (`mode` and
  `protocol-paths` in a single call), and one `git diff` over all paths
  instead of one per path, which it already does.
- `.agents/harness/selftest.sh` — the perf case for the new row.

## Out of scope

- Changing WHAT the guard detects. The boundary's coverage is settled by
  issue #114 and is not this plan's to narrow. Making it cheaper must not
  make it blinder — in particular, do not reintroduce a filter that skips
  paths absent from the worktree: that was a regression, and deleting a path
  is the case it broke.
- Making the guard cache anything across Stops. State that survives a turn is
  a new failure mode for a hook whose whole job is to read current git facts.
- Raising an existing budget literal to accommodate this work.

## Acceptance

- `./joharness.sh perf handover-guard` — prints a counted number against a
  budget, like the other five rows.
- The number is recorded in the commit that sets the budget, with the command
  that produced it and the date.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests added.
- `./joharness.sh ci` — `ci: pass`.
- Consumer-side, because `handover-guard.sh` ships: the guard's cost is
  measured on a checkout carrying only some protocol paths, not just this one.

## Where to look

- `joharness.sh:perf_rows` — the five rows and their budgets.
- `joharness.sh:perf_count` — the shim counter; note it counts external
  commands, so a builtin loop is free and a `git` call is not.
- `.agents/harness/handover-guard.sh` — the unsupervised boundary block, and
  the `mode` resolution above it. Both fork the entrypoint.
- `.agents/docs/feedback.md` — the perf budget's own doctrine: a ceiling for
  a regression in kind, never a number raised to match the code.

## Traps

- The guard runs on every Stop in every consumer. A measurement taken only
  in canonical, with all six paths present, is not the number a consumer sees.
- `perf_count` needs the entrypoint to be runnable non-interactively; the
  guard reads stdin (a hook payload). `perf_count`'s `</dev/null` exists for
  exactly this and is load-bearing — session-start already ate a loop's stdin
  once and silently dropped a row from the table.
- Do not skip, disable or quarantine a case to make a budget fit.
