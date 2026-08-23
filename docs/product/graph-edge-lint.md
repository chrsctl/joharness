---
requirement: graph-edge-lint
priority: normal
---

<!-- Proposed by extensions-research session 2026-08-23. Merge = ratify. -->

## Goal

Graph edges live in frontmatter; a typo kills an edge silently. `needs:`
naming a plan that does not exist = plan reads free, runs before its input.
Workstream `plan:` typo = claim invisible, two fresh sessions pick same
plan. Plan `requirement:` typo = requirement flagged UNPLANNED while a
plan believes it serves it. Enum fields (`agent`, `urgency`, `effort`,
`status`) outside vocabulary silently default. All checkable from file
existence + frontmatter, derived at read time — no new state. Belongs in
`ci`: session that wrote the typo is the one that cannot see it (same
argument as churn ceiling).

## Satisfied when

- `./joharness.sh ci` red on: plan `needs:`/`requirement:` naming no open
  file at the ref; workstream `plan:` naming no open plan; enum
  frontmatter value outside its vocabulary.
- Stale `Where to look` `path:symbol` anchors warn, never red — code
  moves, staleness rule already says verify at read.
- Selftest case per edge class. Current tree passes clean.

## Constraints

- No status field, no stored index. Read same refs the hooks read.
- Red only on hard facts (file existence, closed vocabulary). Judgment
  calls warn.
