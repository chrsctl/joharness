---
plan: plan-curate-step
urgency: normal
agent: haiku
effort: low
needs: none
requirement: none
issue: none
scope: .claude/commands/plan.md
---

## Goal

A plan written by hand with `/plan` can fail `./joharness.sh ci` on a
mechanical scope repair: a path claimed by 3+ plans unmarked ("is declared
by N plans and unmarked — shared: it"), which `./joharness.sh curate
--apply` fixes by itself. The clerk already runs `curate --apply` before its
`ci` (`.claude/commands/clerk.md` §4); `/plan` does not, so the writer meets
a red `ci` it could have avoided. Seen in session 2026-10-22 (PR #525's first
`ci` run). The owner agreed to add the step.

## Scope

- `.claude/commands/plan.md` — step 4 currently reads
  "`./joharness.sh ci` — graph lint green (edges resolve, vocabulary
  holds)." Insert before it a step: "`./joharness.sh curate --apply`, then
  `./joharness.sh curate`: fix by hand what it still names on your plan
  (a `PROPOSE` line is the human's — say it in the pull request body)."
  Renumber the steps after it. Nothing else in the file changes.

## Out of scope

- Any change to `curate`, its threshold `JOHARNESS_CURATE_REGISTRY`, or the
  `ci` rule.
- `.claude/commands/clerk.md`, which already has the step.

## Acceptance

- `grep -n "curate --apply" .claude/commands/plan.md` — one line, before
  the line holding `./joharness.sh ci`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan `ci` calls SHIPS: `.claude/commands/plan.md` reaches every consumer
  at its next sync; its `ci` runs the same graph lint.

## Where to look

- `.claude/commands/plan.md` numbered steps 1-5.
- `.claude/commands/clerk.md` §4 — "run `./joharness.sh curate --apply`,
  then `./joharness.sh curate` and fix by hand what it still names on your
  new plans, then `./joharness.sh ci`": the wording to mirror.

## Traps

- No edit to core paths (`./joharness.sh protocol-paths`).
- Docs state status quo: no dates in `plan.md` (`.agents/docs/caveman.md`).
