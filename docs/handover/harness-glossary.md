---
workstream: harness-glossary
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: harness-glossary
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Write the glossary, add the lint, sweep the non-canonical wordings, cover both
---

## Goal

Plan `docs/plans/harness-glossary.md`: the same node has two names in files
every session loads. The glossary fixes each contested term, names the
wordings that are not it, and a lint stage keeps it from rotting into a wish.

## Decisions

- Counts RE-COUNTED here before any of them ship, because the plan's own
  figures had already drifted twice and it says so:
  `grep -rnoi "<term>" --include=*.md --include=*.sh . | grep -v '^./.git' | wc -l`
  on 2026-08-28 gives workstream file 205, handover file 14, agent tier 10,
  model tier 6, environment layer 24, env layer 5. The plan quoted 146 / 12
  at 2026-08-24 and noted 208 by 2026-08-27. Nothing here quotes a figure
  without that command beside it.
- Files using BOTH "workstream file" and "handover file" today: eight, not
  the five the plan names — `docs/plans/fork-seam-rules.md`, this plan, and
  `docs/research/glossary-enforcement.md` joined since it was written.

## Rejected

(pending)

## Review

(pending)

## Blockers

None.

## Where to look

- `joharness.sh:lint_graph` — the stage shape a new lint copies.
- `.agents/docs/graph.md` Nodes — the closest thing to a canonical vocabulary.
- `docs/research/glossary-enforcement.md` — prior research for this plan.
