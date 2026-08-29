---
workstream: research-node
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: research-node
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Refute every new gate, then review at opus depth with the verifier.
---

## Goal

Give research the standing of a plan: a file shape, a row in the graph, a
line in the queue, a lint. Not a research methodology — the node is what
makes findings survive the session that made them.

## Decisions

- Recounted before building, as the plan tells its reader to: `ls
  docs/research/*.md | wc -l` on `origin/main` b482364, 2026-08-29 → **4**,
  the same four the plan names. Its "went stale within a day" warning has
  not fired again. Their frontmatter already agrees on five fields
  (`research`, `urgency`, `agent`, `effort`, `graduates`) — that is the
  template's first draft, not an invention.

## Decisions (continued)

- **Research counts as queue work at the EDGE, not only in the listing.**
  The plan's scope for the hook says "listed beside plans" and stops there.
  Listing alone leaves two false negatives: no plans plus open questions
  printed "edge reached: done", and no FREE plan plus open questions did the
  same — under unsupervised that reads as an order to invent a backlog while
  real queue work sits unclaimed. Both branches now check the question count.
- **Questions are not folded into the plan `rows` table.** They are ranked
  the same way (urgent, then oldest) but carry no `needs`, no `scope` and no
  claim, so a shared row would have four empty columns inviting somebody to
  fill them.
- **Verification records who and where, never when.** The plan names this
  collision (provenance rule against the requirement's "who checked") and
  says decide once, in the README. Decided there; the same commit removed
  the hand-written `Checked 2026-08-25` from all four instances and changed
  nothing else in them.

## Rejected

- (nothing yet)

## Review

(no round yet)

## Blockers

None.

## Where to look

- `.agents/docs/plans/README.md` + `TEMPLATE.md` — the shape to mirror.
- `.agents/docs/graph.md` Nodes/Edges — two tables gaining rows; Rules
  forbids a store, an index, a status field.
- `joharness.sh:lint_graph` — reuse, do not parallel.
- `.agents/harness/queue-context.sh` — where `blocked by:` is printed.
- `docs/research/*.md` — the four instances; `glossary-enforcement` has no
  `## Method` and is the one known divergence.
