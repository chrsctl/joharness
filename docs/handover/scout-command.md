---
workstream: scout-command
status: in-progress
branch: claude/scout-command
pr: none
plan: scout-command
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: opus
updated: 2026-10-09
next: Edge review (opus: lenses + verifier), then retire with the requirement and PR
---

## Goal

`docs/product/scout-role.md`, bullets three to six: the scout role itself —
the command file a spawned scout follows, the orchestrator's spawn rule,
`/start`'s routing, the Roles row and the bound. Last plan of the
requirement: its pull request deletes `docs/product/scout-role.md`.
Supervised session at the human's ask.

## Decisions

- `start.md` routes nothing to `/scout`: one paragraph says a drain `scout :`
  block is never the session's item (scout-cycle R-f), per the plan as
  updated by scout-cycle r56.
- NOTHING TO PROPOSE still pushes the claim's retire: the retire is what
  dates the next window (scout-cycle reads deletions on unmerged branches).
- One line beyond the plan's scope: `.agents/docs/research/README.md` said
  "Sessions file questions, never requirements" with no exception — a
  literal reader would read the scout as a violation. It now names the
  exception and points at the Bounds paragraph.
- The scout's own rules restated from what scout-cycle reads: the file
  path is the identity; `done` holds until the retire; `abandoned` is the
  janitor's word; automerge from the base branch's conf, never set by the
  scout.

## Rejected

## Review

## Blockers

None.
