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
  DEFAULT branch (documented GitHub behaviour, not measured here), so a workflow added on a work branch is undispatchable
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
  `.agents/docs/consumer-repos.md` ("Update: consumer CI") spells the route
  as "run that
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

Opus tier, adversarial, three lenses (correctness / security / does-it-
reproduce), run against this diff before the retire commit. r1 and r2 are
pre-existing and not in this diff; r3-r6 are findings against my own:

- r1 (open, not mine to fix here): `.agents/harness/handover-context.sh:files_at`
  is what the in-flight list is built from (`git ls-tree`), instead of
  `changed_at` (diff vs merge-base), which is already written a few lines
  below it in the same file. So a branch that merely INHERITS a workstream file is
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
- r3 (fixed): every "Where to look" anchor in the first draft of both files
  used a line number (`handover-context.sh:199`, `joharness.sh:559`,
  `selftest.sh:128`). `.agents/docs/plans/README.md` is explicit that anchors
  are `path:symbol` and never a line: `lint_anchors` splits at the first `:`
  and checks the PATH only, so a stale line number stays green forever. The
  lint would have passed all three while pointing at nothing. Rewritten to
  symbols.
- r4 (fixed, in the plan): the plan leans on `selftest_inert_diff` to skip
  `perf` on a docs-only branch, and this very run shows that skip cannot
  always decide — `ci` here printed `churn: not measurable here (no
  merge-base; shallow checkout or base branch)` and ran the full selftest
  anyway, on a branch touching only `docs/`. It fails safe (the guard runs
  when it cannot tell), but an implementer who assumes docs-only branches
  never pay for `perf` will be wrong on every shallow checkout. Confirmed
  as the mechanism and not a one-off: after the branch was pushed and the
  merge-base resolved, the same `ci` on the same diff skipped the selftest.
  Said out loud in the plan rather than discovered later.
- r5 (fixed, in the plan): the shim directory is a directory this guard
  prepends to `PATH` and then runs `git` out of. A predictable path under a
  shared temp dir is an injection point — `mktemp -d` with 0700, and the
  real binaries resolved to absolute paths BEFORE the dir goes on `PATH`,
  are requirements and not style. Written into the plan's scope.
- r6 (fixed): the default-branch constraint on `workflow_dispatch` was
  stated here as flatly as the dispatch result, and the two are not the same
  kind of claim. The run proved `actions: write` and the canonical guard;
  it proved nothing about branch registration, which is documented GitHub
  behaviour I did not test on this repo. Attributed, not measured.

## Blockers

None.

## Where to look

- `docs/plans/perf-budget.md` — the plan this workstream claims.
- `.agents/harness/selftest.sh:commit_all` — the PATH stub sits just above
  it; the shim counter generalizes that trick, and its comment says why
  stubbing does not lower the bar.
- `joharness.sh:cmd_ci` — the churn threshold block; the budgets go beside
  it in the same warn/red/override shape.
- `.github/workflows/update.yml` — the `skip on canonical` guard that made
  the dispatch test safe, and the `GITHUB_TOKEN` trap in its header comment.
