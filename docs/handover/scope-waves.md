---
workstream: scope-waves
status: in-progress
branch: claude/scope-waves-gxb4i4
pr: none
session: https://claude.ai/code/session_016Fb42AZrNDN76pKG3gNQCP
agent: sonnet
updated: 2026-08-22
next: Add scope frontmatter to plans, partition free plans into disjoint waves in queue-context.sh, cover in selftest
---

## Goal

The queue hook promises "free plans are independent, safe to run in
parallel sessions" — asserted, never checked. `needs` declares result
dependency only; two plans with `needs: none` can both name the same file
in prose and collide at merge. It happened five times in two days: #5, #7
and #8 all edited cmd_ci and selftest.sh, then #18-#21 stacked four more
edits on selftest.sh, every collision discovered at push time. Plans get a
`scope:` frontmatter field (paths the plan will touch); the hook
partitions free plans into waves whose declared scopes are pairwise
disjoint, so "safe in parallel" becomes a computed claim with the
conflicting pair named when it is not.

## Decisions

- Overlap = equal path, or one a directory prefix of the other at a /
  boundary. Literal prefixes, no globs: globs cannot be intersected
  cheaply in bash, and a plan that cannot name its paths as prefixes does
  not know its scope yet.
- Greedy first-fit partition in queue order (urgent first). Optimal graph
  coloring buys nothing here: the point is naming the conflicts, not
  minimizing wave count.
- Plans without scope stay listed, labeled unprovable, with the one-line
  fix named. Missing scope must not silently serialize the queue, and it
  must not silently inherit the old unconditional promise either.
- Zero scoped plans = output unchanged from today, so existing repos see
  no behavior change until a plan opts in.

## Rejected

- Computing scopes from the plan's Scope prose section. Free text; the
  frontmatter is the machine-readable layer, same split as needs vs
  the body (docs/graph.md).
- Glob patterns in scope. Intersection of two globs is not decidable with
  bash tooling at hook cost; prefixes cover the real cases (a file, a
  directory, a layer).
- Enforcing scope at claim time (refuse overlapping claims). The overlap
  warning at spawn time is the graph doctrine move: make it visible,
  leave the judgment with the human — same call as churn and rot.

## Blockers

None.

## Where to look

- harness/queue-context.sh — the wave partition, in the fan-out section.
- docs/plans/TEMPLATE.md, docs/plans/README.md — the field.
- docs/graph.md — scope belongs in the edge table.
