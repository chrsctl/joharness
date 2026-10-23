---
plan: plan-assumptions
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .agents/docs/plans/TEMPLATE.md, shared:.agents/docs/plans/README.md, .claude/commands/plan.md, shared:.claude/commands/manage.md, shared:joharness.sh, .agents/harness/selftest/assumptions-lint.sh, shared:.agents/harness/selftest.sh
---

## Goal

In GSD Core, the human settles a phase's guesses in a Discuss step before
planning (`agents/gsd-assumptions-analyzer.md` returns assumptions with
file-path evidence and confidence). Our sessions run with no human, so a
plan's guesses surface only after code is built on them. Make them
explicit. A plan lists its assumptions, each with evidence and confidence,
and the manager confirms or refutes each one before the build. The result
moves into the workstream file's `## Decisions`.

## Scope

- `.agents/docs/plans/TEMPLATE.md`: a new `## Assumptions` section after
  Scope. One line per assumption: `- A1: <claim> — evidence: <path:symbol
  or command> — confidence: high|medium|low`. If the plan rests on none,
  the section holds one line saying so.
- `.agents/docs/plans/README.md` "Shape" and `.claude/commands/plan.md`
  step 3: the section described as one bullet each.
- `.claude/commands/manage.md` Build: before the first worker, check every
  `A<n>`. Write `- A<n>: confirmed|refuted — <evidence>` into
  `## Decisions`. A refuted assumption means fixing the plan on the branch
  first.
- `joharness.sh`, in the lint `lint_plans_in_diff` drives: a plan ADDED in
  this branch's diff with no `## Assumptions` heading reds ci.
  Pre-existing plans and consumers' existing queues are untouched.
- `.agents/harness/selftest/assumptions-lint.sh` (new topic), registered.

## Out of scope

- A lint on plans that already exist. A consumer's queue would turn red at
  its next sync.
- Machine-checking evidence paths. `lint_anchors` already warns on stale
  paths, and assumptions get the same warn-only treatment at most.
- An analyzer subagent. The plan author writes the section.

## Acceptance

- `./joharness.sh ci` — `ci: pass`, and the selftest prints the cases:
  - a plan added in the diff without `## Assumptions` is red, naming the
    file;
  - the same plan already on the base and not in the diff is not red;
  - a plan with the section is green.
- `grep -c '^## Assumptions' .agents/docs/plans/TEMPLATE.md` — `1`.
- `wc -c < .claude/commands/manage.md` — within its reading-budget bound.

## Where to look

- `joharness.sh:lint_plans_in_diff` — diff-scoped plan lint, the place for a diff-only rule.
- `joharness.sh:section_paths` — how a section's lines are read.
- `.agents/docs/plans/TEMPLATE.md` — sections and the comment block ci reads.
- `.claude/commands/manage.md` — "2. Decompose, then fan out to workers".

## Traps

- This is a SHIPS change: consumers receive the new lint. Diff-only
  scoping is what keeps their old plans green. Test that specifically.
- manage.md's headroom is under 800 bytes, and plan `plan-soundness-check`
  edits it too. The second to merge reconciles without raising the bound.
- Every plan this branch itself adds must carry the new section, this
  plan's own sibling plans included, once the lint is live.
- A test for the red case must FAIL without the lint.
