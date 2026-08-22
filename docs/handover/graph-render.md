---
workstream: graph-render
status: in-progress
branch: claude/graph-render-5hz6ju
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
agent: sonnet
updated: 2026-08-22
next: Derive the mermaid graph from the same primitives the hooks read; selftest against the existing fixture
---

## Goal

docs/graph.md names three formalization steps in value order and holds the
third: "optional joharness.sh graph mermaid renderer, derived at read time,
never stored - held until text queue stops being legible." Since that
sentence: a product tier above plans (#11), needs edges and machine-readable
claims (#8), churn measurement per branch (#20, open). Five node types,
four edge types, spread across three hook outputs. The threshold the hold
names is arriving. One command prints the whole state as fenced mermaid;
GitHub renders it natively in any comment, so the graph is one paste away
from every PR discussion.

## Decisions

- Derived at read time from origin/<base>, exactly like queue-context.sh;
  nothing stored, nothing cached (docs/graph.md doctrine).
- Output is fenced ```mermaid, because the consumer is a markdown paste
  (PR comment, issue). Piping raw mermaid elsewhere = strip two lines.
- Node ids sanitized to [a-z0-9_]; labels keep the real names.
- Churn folds in as a node class, not an edge: it is a property of a
  branch, and red is what a party demo needs.

## Rejected

- Storing an image or .mmd artifact in the repo. Derived state, rots.
- Rendering only plans. The graph's point is the joins a text list cannot
  show: requirement without plan, plan claimed by branch, branch churning.

## Blockers

None.

## Where to look

- joharness.sh:cmd_graph - the renderer.
- docs/graph.md - the ontology it draws, and the hold it answers.
