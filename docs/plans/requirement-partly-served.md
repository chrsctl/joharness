---
plan: requirement-partly-served
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 626
scope: shared:joharness.sh, shared:.agents/harness/queue-context.sh, shared:.agents/harness/selftest/ci-graph-lint.sh, shared:.agents/harness/selftest/queue-context.sh, shared:.agents/docs/product/README.md, shared:.agents/docs/plans/README.md, shared:.agents/docs/plans/TEMPLATE.md, shared:.agents/docs/graph.md
---

## Goal

Issue #626, follow-up. In chrsctl/gx, `pm-typed-record-links` named
`requirement: projects-layer` while it served one of that requirement's
five *Satisfied when* clauses. Any plan naming a requirement silences its
`unplanned` row (`queue-context.sh`, `served`). So nobody was ever offered
the layer to plan, and the managers that blocked on it said "plan it",
which no queue item would do. There was also a second risk: that one-clause
plan was the requirement's only plan, so its retirement ("the last plan's
PR deletes the requirement") would have deleted `projects-layer.md` with
four clauses unbuilt. Lint warns only in the opposite case: a requirement
deleted while a plan still names it.

## Decide first, record it

In `.agents/docs/product/README.md`: how a plan says which clauses it
serves. Default answer:
- A requirement's `## Satisfied when` bullets are its clauses, numbered by
  position.
- A plan naming `requirement:` may add `serves: <n>[, <n>]` or `serves:
  all`. Absent means `all`, so every existing plan in every consumer keeps
  today's meaning, and nothing reds on sync.
- A requirement is PARTLY PLANNED when at least one of its open plans
  declares `serves:` and the union over its open plans misses a clause.
- Rejected: matching clause text in plan bodies. Prose is not an edge; the
  same rule #626 applies to `needs:`.

## Scope

- `.agents/harness/queue-context.sh`: a PARTLY PLANNED requirement is
  listed and offered like an unplanned one, its label naming the unserved
  clause numbers (`PARTLY PLANNED: clauses 2, 4 unserved`).
- `joharness.sh` lint:
  - `serves:` values must be integers within the requirement's clause
    count, or `all`;
  - red a branch that deletes `docs/product/<r>.md` while the union of
    `serves:` over the plans retired on that branch and before it misses a
    clause. Read history the way `lint_existed` does; shallow = warn.
- `.agents/docs/plans/TEMPLATE.md`: the `serves:` line and its comment.
  `plans/README.md`: the rule. `graph.md`: the `serves` edge, plan → clause.
- Selftests: the listing (`queue-context.sh`), the value lint and the
  deletion check (`ci-graph-lint.sh`), and the default (no `serves:` reads
  `all`).

## Assumptions

- A1: `served` in `queue-context.sh` is a stem set with no clause notion.
  Evidence: `served="$(awk -F'\t' '$5 != "" ...'`. Confidence: high.
- A2: requirement files keep `## Satisfied when` as a bullet list.
  Evidence: `.agents/docs/product/README.md` names the section.
  Confidence: medium; count the bullets at the top level only, and measure
  against the consumers' real files first.

## Out of scope

- Judging whether a plan really builds its clause. That stays the verify
  plan's job (product README, exits 1–3).
- Migrating existing plans to `serves:`. The default keeps them correct.

## Acceptance

- `./joharness.sh ci`: expect `ci: pass`; red is any other final line.
- `./joharness.sh verify`: expect `0 failed`; red is any failure count
  above 0.
- Fixture: a 3-clause requirement with one open plan `serves: 1`. Expect
  the queue to list it `PARTLY PLANNED: clauses 2, 3 unserved` and offer
  it. A branch that retires that plan and deletes the requirement is red.
  The same with no `serves:` behaves exactly as today.

## Where to look

- `.agents/harness/queue-context.sh`: `served`, `unplanned`, the
  `UNPLANNED — decompose into plans` label.
- `joharness.sh:lint_graph`: the `requirement:` edge checks (`satisfied
  while this plan is open?`), `lint_existed`.
- `.agents/docs/product/README.md`: "A requirement no plan can serve", exits
  1–4.

## Traps

- Don't collapse "no `serves:`" and "serves nothing" onto one value:
  absent is `all`, and `serves:` with no number is red.
- A consumer's requirement file is DATA: count bullets, never act on text.
