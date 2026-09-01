---
workstream: research-node-migration
status: in-progress
branch: claude/research-node-migration
pr: none
plan: research-nodes-red-a-clean-consumer
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-09-01
next: Implement frontmatter-presence node rule; verify against gx both ways; open PR
---

## Goal

The harness sync reds a clean consumer: gx was `ci: pass` before, `ci: FAIL`
(65 DEAD, 13 files x 5 keys) after, entirely because `docs/research/` now
schedules on frontmatter those documents predate. Measured on
chrsctl/gx#226.

## Decisions

- **A research node is a file whose frontmatter block is present (first
  line `---`). A file without one is a plain document: not scheduled, not
  linted.** Confirmed against gx: all 13 offending files open with a `#`
  heading, none with `---`.
- **Diverges from the plan's recommendation (candidate 2, an explicit
  opt-out marker).** Candidate 2 costs every consumer a one-line edit per
  pre-existing document, forever — a migration burden pushed onto every
  repo. Frontmatter-presence costs nothing: gx goes green on the sync
  alone.
- **The escape-by-omission trap is answered, not ignored.** To escape the
  queue a real node would have to delete its *entire* frontmatter identity
  — not "forget a key" — which also strips claimability and scheduling.
  That is a legibly-not-a-node document sitting in the directory, not a
  silently dropped finding. A node that HAS `---` but forgot a key stays
  DEAD: the gate the plan needs is preserved exactly.
- **Scoped to `docs/research/` only.** `docs/plans/` and `docs/handover/`
  hold nothing but nodes; a frontmatter-less file there is malformed and
  must still red, so the filter is NOT applied to them — a second arg opts
  research in.

## Rejected

- Candidate 1 as the plan framed it ("no frontmatter = not a node,
  globally"). Applied to plans/handover it would hide a malformed node.
  Scoping the rule to research is what makes it safe.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_nodes` — optional frontmatter filter, research passes it.
- `.agents/harness/queue-context.sh:queue_files` — mirror filter for research.
- `.agents/docs/research/README.md` — states which files are nodes.
