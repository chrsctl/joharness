---
workstream: plan-ship-scope
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: sonnet
updated: 2026-08-28
next: Record the verifier round, retire plan + workstream files, open the pull request.
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

Round 1, self-found while building. Recorded after the fix rather than before
it, which is not the protocol's order — noted here rather than tidied away.

- r1: `.agents/env/<name>/` read as canonical-only. The selected layer ships
  (`sync-to-consumer.sh`, LAYER_IN_CANONICAL) but sits in no static array, so
  membership alone called a layer plan private. A wrong verdict is worse than
  none: it tells an author to skip a check they needed. (fixed)
- r2: root `AGENTS.md` read as canonical-only. Spliced, not copied —
  everything above the Part 2 marker reaches every consumer, which is exactly
  why it is absent from `FILES`. Same class as r1. (fixed)
- r3: the new selftest block used fixture variable `swork`, already owned by
  the perf-budget fixture. Three perf cases then ran against the wrong repo
  and went red — a failure that reads as "the perf gate broke". Renamed
  `shipwork`. (fixed)
- r4: `local -a plans` collided by name with a string `plans` in another
  function; shellcheck tracks a name file-wide and turned it into SC2178/2128.
  Would have failed `ci`. Renamed `ship_plans`. (fixed)
- r5: the layer test named a real layer inside `.agents/harness/selftest.sh` —
  a second carve-out, which Part 2 makes a red run, not a judgement call. The
  structure check caught it. Fictional layer name instead. (fixed)
- r6: test helper `${1:-all}` made an empty argument mean "all", so the
  default-mode cases silently asserted against all-mode output. Found by the
  cases themselves failing. `${1}`. (fixed)

## Blockers

None. An earlier version of this section claimed this branch reds a third
perf row; that was wrong and the correction matters more than the claim did.

`./joharness.sh ci` is RED on `main`, and was before this branch existed.
Measured on a clean worktree of `origin/main` (no plan file, no workstream
file), `./joharness.sh perf`, 2026-08-28:

```
   graph               273      260  OVER by 13
   session-start       720      700  OVER by 20
   queue-context       369      350  OVER by 19
661 passed, 1 failed  ("a tree inside budget is green")
```

Same three rows on this branch: `graph` 273, `queue-context` 369 — identical
— and `session-start` 723, +3 for this branch's two files, both of which the
retire commit deletes before the pull request opens.

The first measurement of this said 262 / 694 / 361 and read as "adding a plan
takes a third row over". It was taken before `git fetch origin main`: fewer
refs, fewer forks, every row lower. The rows were already over; the fetch, not
the plan file, moved the numbers. A measured number carries what produced it —
the command AND the state — and that one carried only half.

No `perf_rows` literal raised. The regression is real, it is `main`'s, and it
wants its own plan: `perf_report`'s own text says find the loop that grew a
fork rather than raise the number to match.

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
