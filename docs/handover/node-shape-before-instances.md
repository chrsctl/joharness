---
workstream: node-shape-before-instances
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: node-shape-before-instances
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Implement the unknown-type warning in lint_graph, derived from the tree.
---

## Goal

Instances of a node type can land before the type exists and nothing says
so. Four research files sat on `main` for days with no README, no TEMPLATE,
no listing and no lint. `lint_graph` checks EDGES between nodes; nothing
checked that a directory of nodes has a type at all.

## Decisions

- **The signal is self-naming, not frontmatter-in-general.** Every node
  file in this graph names itself in its first frontmatter key:
  `plan: <stem>`, `research: <stem>`, `requirement: <stem>`,
  `workstream: <stem>`. Verified across all 11 node files and 4 templates
  on `origin/main` f806d5b before writing any code. "Has frontmatter" would
  warn on any `docs/adr/` a consumer keeps, and a false warning trains
  sessions to ignore the channel the real findings ride on
  (`joharness.sh:lint_anchors` carries that lesson already).
- **A type is implemented when `.agents/docs/<type>/` exists.** Derived
  from the tree at read time, no registry to maintain — the trap the plan
  names. True of all four current types.

## Rejected

- (nothing yet)

## Review

(no round yet)

## Blockers

None.

## Where to look

- `joharness.sh:lint_graph` — the warn/red split this joins.
- `joharness.sh:lint_nodes` — the TEMPLATE/README/VISION filter reused.
