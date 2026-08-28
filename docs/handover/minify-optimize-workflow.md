---
workstream: minify-optimize-workflow
status: in-progress
branch: claude/minify-optimize-workflow-kcq2r3
pr: none
plan: perf-budget
session: https://claude.ai/code/session_014ojqiTtBebzJWwiVSApHTe
agent: opus
updated: 2026-08-28
next: Implement docs/plans/perf-budget.md — cmd_perf, the PATH shim counter, budgets beside the churn thresholds, selftest cases
---

## Goal

Human: "Plan automatic workflow for minify optimize (before create PR?)",
then "We currently do not run the workflow from any agent how could we do
it". Two questions: what the automation should be, and whether an agent can
trigger a GitHub workflow at all. Answered second first, because the answer
decided the shape of the first.

## Decisions

- **Dispatch works, and is the wrong tool for a gate.** `workflow_dispatch`
  via `mcp__github__actions_run_trigger` is available to a session — proven,
  not assumed (below). But a gate wants to fire before the pull request, and
  a dispatch cannot: GitHub registers a dispatchable workflow only from the
  DEFAULT branch, so a workflow added on a work branch is undispatchable
  until it merges. `ci.yml`'s own header already names the fix — the checks
  live in `joharness.sh ci` so a session runs them before opening the pull
  request. So: subcommand, registered in `cmd_ci`, no workflow edit.
- **Agent dispatch, proven 2026-08-28.** Fired `update.yml` on `main`
  (`actions_run_trigger`, `method: run_workflow`) → HTTP 204, run
  33205534752, conclusion `success` in 7s. `skip on canonical` matched
  `JOHARNESS_CANONICAL=1`; `clone canonical`, `run sync` and `commit and
  open pull request` all `skipped`. Nothing committed, no pull request. The
  session's token therefore has `actions: write`, and the run attributes to
  `chrsctl` — the human's account, not a bot, because the MCP server carries
  their token. Consequence worth knowing before anyone builds on this: a
  dispatched run is indistinguishable in the Actions tab from the human
  clicking the button.
- **The route is undocumented, not missing.** `grep -rn
  "workflow_dispatch\|actions_run_trigger\|gh workflow" .agents/ docs/
  joharness.sh` returns two hits, both prose;
  `.agents/docs/consumer-repos.md:133` spells the route as "run that
  workflow from the consumer's Actions tab" — a human's browser. No document
  tells a session it may dispatch, or names the tool. That gap is real and
  is NOT this plan.
- **Counts gate, seconds do not.** Subprocess counts are deterministic for a
  given code path; wall-clock on a shared runner is not. A guard that goes
  red for the weather gets re-run rather than read.
- **Budget as literal, not as stored data.** Every other measure here counts
  from git at read time and stores nothing. A budget is a threshold, not a
  measurement, so it belongs where `JOHARNESS_CHURN_THRESHOLD` lives.

## Rejected

- **A new dispatchable `perf.yml`.** Default-branch registration makes its
  first run impossible before its own merge, and it would duplicate a gate
  `ci.yml` already delivers by running `./joharness.sh ci`.
- **`repository_dispatch`.** Same default-branch constraint, needs a PAT,
  and there is no MCP method for it — raw API for strictly less.
- **A scheduled sweep that opens pull requests.** Viable, and the one shape
  where dispatch earns its place, but it inherits `update.yml`'s recorded
  trap: a pull request opened with the workflow's own `GITHUB_TOKEN` gets NO
  `ci` runs. Needs `JOHARNESS_UPDATE_TOKEN` to be worth anything. Human
  chose the guard first.
- **Storing the budgets in a `.tsv`.** See Decisions — it is the one shape
  this repo has consistently refused.

## Review

Not started — nothing implemented yet. Two findings from the scoping
research, both pre-existing and neither in this diff:

- r1 (open, not mine to fix here): `.agents/harness/handover-context.sh:199`
  builds the in-flight list with `files_at()` (`git ls-tree`, line 77)
  instead of `changed_at()` (diff vs merge-base, line 85, already written
  three lines below). So a branch that merely INHERITS a workstream file is
  reported as working on it. This is why `joharness-minify-optimize` shows
  on four branches: it merged as PR 54 and was swept from `main` in
  `a87f137`; all four branches have merge-bases from 2026-08-25, before that
  sweep, and `git diff --name-only <merge-base> <branch> --
  docs/handover/joharness-minify-optimize.md` is empty for every one of
  them. Same defect PR 54 recorded as its own r13 and left pre-existing, and
  the exact rule AGENTS.md step 4 says six merged edges paid for. Needs its
  own plan.
- r2 (open, addressed by `perf-budget`): PR 54's measurement table carries
  no commands. `git log --all -p --grep=subprocess` finds prose and no tool,
  so "1262 → 639 subprocesses" cannot be re-counted by anyone. That is the
  written-number failure AGENTS.md names, inside the workstream that argued
  hardest for counting.

## Blockers

None.

## Where to look

- `docs/plans/perf-budget.md` — the plan this workstream claims.
- `.agents/harness/selftest.sh:128` — the PATH stub the shim counter
  generalizes, with the comment on why stubbing does not lower the bar.
- `joharness.sh:559` — the churn threshold block; the budgets go beside it
  in the same warn/red/override shape.
- `.github/workflows/update.yml` — the `skip on canonical` guard that made
  the dispatch test safe, and the `GITHUB_TOKEN` trap in its header comment.
