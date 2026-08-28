---
workstream: plan-ship-scope
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: sonnet
updated: 2026-08-28
next: Decide the perf-budget blocker below with the human, then open the pull request adding docs/plans/plan-ship-scope.md to main.
---

## Goal

Human asked whether this repo needs a cleaner split between what is framework
for consumers and what is this repo's own plan work, pointing at
`docs/plans/finding-id-lint.md`. Research said the split they named is already
mechanical and enforced, and that a different gap sits next to it: nothing
tells a plan author that this repo's plans mostly edit shipped surface. This
branch writes the plan for that gap. It does not implement it.

## Decisions

- `plan: none` in this frontmatter, deliberately. This branch AUTHORS
  `plan-ship-scope`; it does not implement it. Naming it here would mark the
  plan claimed in the queue and stop it being suggested to the session that
  should run it.
- Derive the ships/canonical-only verdict from the existing `scope:`
  frontmatter rather than adding a field. Same reasoning the queue already
  uses for having no `status` field on plans: a field is only as fresh as the
  last hurried session.
- Classifier parses `.agents/scripts/sync-to-consumer.sh`'s lists instead of
  restating them. A second copy of the ship boundary is the defect the plan
  exists to prevent, so the plan must not introduce one.
- WARN, never red. `finding-id-lint` argues this for its own stage and the
  argument transfers unchanged: no backtest, and a gate that reds a working
  branch gets routed around.
- Did NOT raise any `perf_rows` literal to absorb this branch's cost. See
  Blockers — the rule there is explicit that a number is not raised to match,
  and this branch adds no work to any entrypoint.

## Rejected

- Splitting `docs/plans/` into `framework/` and `local/` subdirectories — the
  human's own first suggestion, and the obvious move. It duplicates a boundary
  `sync-to-consumer.sh` already owns, so the two disagree the first time a
  path moves between `DIRS` and `CANONICAL_ONLY`. The directory-level split is
  already clean: `docs/` appears in neither `FILES` nor `DIRS`, and
  `bootstrap-consumer.sh:385` strips joharness's plans from a new consumer.
  `finding-id-lint.md` cannot reach a child repo today.
- Asserting the live 9-of-10 count in the plan's Acceptance. The number moves
  as plans merge and as `CANONICAL_ONLY` grows. It belongs in the Goal as a
  measurement with its command and date; the fixtures carry the assertions.

## Review

Not yet run: no edge. Docs-only diff, no pull request open. Edge review per
Loop step 5 happens when the PR opens, at sonnet depth with a verifier pass.

## Blockers

`./joharness.sh ci` is RED on this repo's `main`, before this branch changes
anything. Measured 2026-08-28 at `ec5cd2c`, tree identical to `origin/main`
(`git diff --stat origin/main HEAD` empty), `./joharness.sh ci`:

```
   graph               262      260  OVER by 2
   queue-context       361      350  OVER by 11
   session-start       694      700  ok
639 passed, 1 failed  ("a tree inside budget is green")
```

Two rows were already over. Not this branch's, and not this branch's to fix.

The part that IS this branch's: this branch's two files move `session-start`
from 694 to 715, over its 700 budget — a third red row. Same command, same
commit, measured three ways: 694 with neither file, 712 with the plan file
only, 715 with both. `perf_count` counts shimmed forks, and the session-start
hook forks per queued plan and per in-flight workstream file, so the cost is
**18 forks per plan file** at n=10→11 and 3 more for the workstream file.

That is the finding, and it outlives this branch: the queue's own growth
spends the entrypoint budget, so the NEXT plan added to `main` by anyone reds
`session-start` whether or not this one merges. `queue-context` at +11 over 10
plans says it already happened once there.

Not fixed here on purpose. `perf_report`'s own remedy text says a budget is a
ceiling for a regression in kind, that the number is not raised to match, and
that raising the literal is for genuine new work in an entrypoint — this
branch adds none; it adds one data file. Bumping `SESSION_START` to fit would
be exactly the move the text forbids, and would hide a per-plan cost that
needs its own plan.

Human decision wanted before the pull request opens: land the plan and accept
a third red row on an already-red `main`, or hold it until the queue-cost
regression has a plan of its own.

## Where to look

- `.agents/scripts/sync-to-consumer.sh:162-198` — `FILES`, `DIRS`,
  `CANONICAL_ONLY`, `CANONICAL_ONLY_DIRS`. The boundary, and the plan's input.
- `.agents/harness/README.md` — the ownership boundary in one sentence; the
  planned classifier is that sentence made executable.
- `joharness.sh:perf_rows` / `:perf_count` — the budgets and the fork counter
  behind the Blockers measurement.
- `docs/plans/selftest-split.md:38`, `docs/plans/moment-feedback-hooks.md:56`
  — the two independent prose reinventions that make this a graduation case
  rather than a nice idea.
