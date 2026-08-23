---
workstream: agents-docs-move
status: in-progress
branch: claude/agents-docs-move
pr: none
plan: agents-docs-move
session: https://claude.ai/code/session_0178f1MyS7qfR1ovDhqt4pH8
agent: sonnet
updated: 2026-08-23
next: Move the ten docs and two scripts, then re-point per plan Scope order
---

## Goal

Implement plan agents-docs-move: harness protocol docs to `.agents/docs/`,
sync tools to `.agents/scripts/`, so a child's `docs/` is 100% its own and
the sync ships nothing into `docs/` or `scripts/`.

## Decisions

- update.yml compat: existing consumers' seeded update.yml calls
  canonical's `scripts/sync-to-consumer.sh`, which this plan removes. No
  shim (plan out-of-scope). Seeded update.yml gains a two-path probe so
  new consumers survive future moves; existing consumers' weekly run goes
  red with file-not-found until a one-line edit — documented in
  consumer-repos Migration. Flagged: scope call made alone.
- Legacy warning grows a file tier next to the dir tier: old doc/script
  paths are single files inside dirs that still hold live consumer work,
  so remedy must name files, never `-r` a docs dir.

## Rejected

None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- docs/plans/agents-docs-move.md — the plan; PR #37 diff — the pattern.
