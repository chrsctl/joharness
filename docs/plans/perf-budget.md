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
  the shellcheck stub above `.agents/harness/selftest.sh:commit_all`. One shim per
  wrapped binary (`git`, `awk`, `sed`, `grep`, `sort`, `wc`); each appends a
  line to a counter file, then `exec`s the real binary at an absolute path
  resolved once BEFORE the shim dir goes on PATH. The dir is `mktemp -d`
  with 0700 — this guard prepends it to `PATH` and then runs `git` out of
  it, so a predictable path under a shared temp dir is an injection point,
  not a style question. Deterministic: the same
  code path yields the same count on any machine, which is the property
  wall-clock does not have.
- Budgets live as literals in `joharness.sh`, beside the churn thresholds
  in `joharness.sh:cmd_ci`, with the same env override shape
  (`JOHARNESS_PERF_BUDGET_*`). NOT a data file — see Out of scope.
- Registration is `cmd_ci`, not `ci.yml`: the workflow already runs
  `./joharness.sh ci`, so the guard reaches GitHub with no workflow edit and
  a session runs it pre-PR by running `ci`, which is the split ci.yml's own
  header asks for.
- Skip on a docs-only branch by reusing `joharness.sh:selftest_inert_diff`
  — the guard measures harness code, and a docs branch cannot move the
  counts. Know its limit before relying on it: with no merge-base (shallow
  checkout, or the base branch itself) that skip cannot decide, and the work
  runs anyway. Observed 2026-08-28 on this branch — `./joharness.sh ci`
  printed `churn: not measurable here (no merge-base; shallow checkout or
  base branch)` and ran the full selftest against a diff touching only
  `docs/`. Once the merge-base resolved, the same command on the same diff
  skipped it. Fails safe, but do not promise a docs-only branch never pays.
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
- **A dispatchable `perf.yml`, or any workflow edit.** Settled by test, not
  by preference: a session CAN dispatch — `mcp__github__actions_run_trigger`
  fired `update.yml` on `main` 2026-08-28, HTTP 204, run 33205534752, success
  in 7s with the canonical guard matching and the three sync steps skipped,
  so the token has `actions: write`. It buys nothing here. GitHub registers a
  dispatchable workflow only from the DEFAULT branch (documented behaviour,
  not tested here), so a workflow added on a work branch cannot run before
  its own merge — and a guard that cannot fire pre-PR is the failure `ci.yml`
  was written to avoid. Hence a subcommand in `cmd_ci`, which reaches GitHub
  with no workflow edit at all.
- **The `handover-context.sh:files_at` tree-vs-diff defect.** Found while
  scoping this plan and left open: the in-flight list is built from the TREE
  (`files_at`, `git ls-tree`) rather than the diff (`changed_at`, already
  written a few lines below), so a branch that merely INHERITS a workstream
  file is reported as working on it. That is why `joharness-minify-optimize`
  reads as claimed on four branches — it merged as PR 54 and was swept from
  `main` in `a87f137`, and every one of those branches has a merge-base
  predating the sweep with an empty `git diff --name-only <merge-base>
  <branch> -- docs/handover/joharness-minify-optimize.md`. PR 54 recorded it
  as its own r13. Different bug, wants its own plan; noted here because this
  is the file that survives on `main`.

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
- `.agents/harness/selftest.sh:commit_all` — the PATH stub sits above it,
  with the comment saying why stubbing does not lower the bar. The shim dir
  is that trick, generalized.
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
