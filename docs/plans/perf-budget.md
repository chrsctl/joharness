---
plan: perf-budget
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: joharness.sh, shared:.agents/harness/selftest.sh
---

## Goal

PR 54 cut `ci` from 61.7s to 20.2s and `feedback` from 1262 subprocesses to
639. Nothing re-counts any of it. The numbers were measured by hand in one
session, written into `docs/handover/joharness-minify-optimize.md`, and that
file was swept off `main` in `a87f137` when the work merged — so today the
whole optimization is defended by a table that no longer exists in any tree.
AGENTS.md step 5: "Trust counted numbers, never written numbers", and
"Measured number carries what produced it, same sentence — the command, and
when." PR 54's own table carries no commands; searching history for the
subprocess counting method (`git log --all -p --grep=subprocess`) turns up
prose and no tool. Any commit can hand back the 42 seconds and every gate
stays green.

Make the numbers re-countable, and make a regression red.

## Scope

- `joharness.sh` — new `cmd_perf` / `joharness.sh perf`. Counts external
  command invocations for a fixed set of harness entrypoints (`feedback`,
  `review`, `graph`, `session-start`, and `.agents/harness/queue-context.sh`),
  compares each against a budget, prints a table of metric / counted /
  budget / verdict, exits non-zero on breach.
- Counting method: a PATH shim directory, same trick and same reasoning as
  the shellcheck stub at `.agents/harness/selftest.sh:128`. One shim per
  wrapped binary (`git`, `awk`, `sed`, `grep`, `sort`, `wc`); each appends a
  line to a counter file, then `exec`s the real binary at an absolute path
  resolved once before the shim dir goes on PATH. Deterministic: the same
  code path yields the same count on any machine, which is the property
  wall-clock does not have.
- Budgets live as literals in `joharness.sh`, beside the churn thresholds
  (`joharness.sh:559`), with the same env override shape
  (`JOHARNESS_PERF_BUDGET_*`). NOT a data file — see Out of scope.
- Registration is `cmd_ci`, not `ci.yml`: the workflow already runs
  `./joharness.sh ci`, so the guard reaches GitHub with no workflow edit and
  a session runs it pre-PR by running `ci`, which is the split ci.yml's own
  header asks for.
- Skip on a docs-only branch by reusing `selftest_inert_diff`
  (`joharness.sh:726`) — the guard measures harness code, and a docs branch
  cannot move the counts.
- `.agents/harness/selftest.sh` — cases: a shim counts what the entrypoint
  actually spawns; a budget breach exits non-zero and names the metric; the
  docs-only branch skips and says so; `perf` runs with no network.

## Out of scope

- **Wall-clock as a gate.** Print the seconds beside each count, never fail
  on them. Shared runners vary by more than the margin worth defending, and
  a gate that goes red for the weather is a gate sessions learn to re-run.
- **A stored measurements file.** `cleanup`, the churn measure, the graph
  lint and the feedback scorecard all count from git at read time on purpose
  — "nothing stored, so it cannot rot and cannot be written wrong". A budget
  is a threshold (a decision) not a measurement (a fact), which is why it
  goes where `JOHARNESS_CHURN_THRESHOLD` goes and not into a `.tsv` some
  session has to remember to regenerate.
- **Finding new optimizations.** This plan defends numbers already banked.
  A sweep that hunts fresh waste is separate work and a separate plan.
- **Re-litigating PR 54's cuts.** The fixture shellcheck stub, the single-pass
  frontmatter reader and the one-walk git measures stay as they are.
- **Wrapping every binary.** Six is enough to pin the hot paths; a shim per
  command in `$PATH` buys precision nobody is spending.
- **`.github/workflows/ci.yml`.** Deliberately untouched — see Scope.
- **The `handover-context.sh:199` tree-vs-diff defect.** Real, found while
  scoping this plan, recorded in the workstream file. Different bug, its own
  plan.

## Acceptance

- `./joharness.sh perf` — prints one row per metric with counted value,
  budget and verdict; exits 0 on this branch.
- `JOHARNESS_PERF_BUDGET_FEEDBACK=1 ./joharness.sh perf` — exits non-zero and
  names `feedback` as the breached metric.
- `./joharness.sh perf` run twice on an unchanged tree — byte-identical
  counts. A metric that drifts between two runs of the same code is not a
  budget, and must be dropped or made deterministic before it ships.
- Revert any one of PR 54's cuts in a scratch copy (`gr_fields` back to a
  fork per field is the cheapest), run `perf` — red, naming the metric. Put
  it back — green. A guard green both ways pins nothing (AGENTS.md step 5).
- `./joharness.sh ci` — `ci: pass`, and the run reports `perf` among its
  sections.
- `./joharness.sh ci` on a docs-only branch — `perf` reports skipped, with
  the override spelled out, same shape as the selftest skip.
- `./joharness.sh verify` — 0 failed.
- The workstream file records each budget with the command that produced it
  and the date, in the same sentence.

## Where to look

- `joharness.sh:cmd_ci` — where `perf` registers, and how the selftest skip
  is worded; copy that shape.
- `joharness.sh:selftest_inert_diff` — the docs-only skip, already written.
- `joharness.sh:churn_top` — a threshold with a warn tier, a red tier and an
  env override that can lift it. The precedent for how a number is allowed
  to live in this script.
- `.agents/harness/selftest.sh:128` — the PATH stub, with the comment saying
  why stubbing does not lower the bar. The shim dir is this, generalized.
- `joharness.sh:fb_fix_map`, `joharness.sh:gr_fields` — two of the hot paths
  the budget exists to pin.
- `joharness.sh:check_targets` — how a subcommand enumerates its own subject
  without hardcoding a list.

## Traps

- NEVER skip, disable or quarantine a test to get green. A breached budget
  is either a real regression or a budget that was wrong; both are edits a
  human can read, neither is a deleted case.
- The guard's own test must FAIL without the guard. Revert, run, restore.
- Measured number carries the command that produced it, same sentence.
- Trust counted numbers, never written numbers — including any number in
  this plan. Every figure above is from PR 54's merged workstream file and
  is a hypothesis until re-counted (`.agents/docs/plans/README.md`).
- `.agents/harness/selftest.sh` is marked `shared:`: `selftest-split` will
  move these cases into `.agents/harness/selftest/`. Expect a reconcile, and
  put the cases in a `step` topic that survives the move.
- Adding a section to `cmd_ci` makes `ci` slower — the one gate where that
  is most embarrassing. Measure the added cost and record it; if the guard
  costs more than a second, move it behind the inert-diff skip more
  aggressively rather than accepting it quietly.
