---
plan: short-kebab-name
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: none
---

<!--
Copy to docs/plans/<plan>.md. Queue rules: .agents/docs/plans/README.md.

Write for literal reader. Scope and out-of-scope both explicit; acceptance
= runnable commands with expected output; traps = the Part 2 prohibitions
this plan can trip, one line each.

`needs` = plan names whose RESULT this plan reads; blocked while those
files exist. Related-but-independent = fake edge, leave `none`.
`requirement` = the one this plan serves (docs/product/); hook stops
flagging it unplanned. Last plan of a requirement: its PR deletes the
requirement file too.
`scope` = comma-separated path prefixes this plan will touch (a file, a
directory, a layer). The queue hook partitions free plans into waves of
disjoint scopes — parallel proven inside a wave, the conflicting pair
named across. `none` = independence stays unprovable; the plan is listed
but joins no wave. Prefix a path `shared:` when a reconcile merge there is
routine: marked by BOTH plans, it stops splitting the wave and is named as
the cost instead (.agents/docs/plans/README.md).

`scope` is also what the ship-scope stage reads to say whether this plan's
diff reaches consumers. Incomplete scope, wrong verdict — same field, two
readers.
-->

## Goal

Why this work exists, requester's terms. One paragraph.

## Scope

- `path/new_file.py` — what goes in it.
- `path/existing.py` — what changes.

## Out of scope

- Thing a helpful agent would add. Reason it stays out.

## Acceptance

- `command` — expected output, exact.
- Project suite — all green.
- Plan `ci` calls SHIPS: one check a consumer runs, not only a local one.
  The diff reaches every consumer at its next sync, so a bar met only here
  is met in the one repo that was never the risk.

## Where to look

- `path/to/file.py:symbol` — why this spot matters.

## Traps

- Relevant prohibition, restated. (AGENTS.md Part 2 has reasoning.)
