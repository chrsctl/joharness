---
workstream: clerk-cycle-reads-what-a-clerk-leaves
status: in-progress
branch: claude/clerk-cycle-reads-what-a-clerk-leaves
pr: none
plan: clerk-cycle-reads-what-a-clerk-leaves
issue: 424
session: https://claude.ai/code/session_01TdyVr1vRDVyumkSVDrJCgi
agent: opus
updated: 2026-10-12
next: Research the clerk readers in joharness.sh, record the no-op record decision, then code
---

## Goal

The clerk cycle is read from `docs/handover/clerk-*`, a file no clerk writes,
so dispatch reads DUE forever, never shows a clerk IN FLIGHT, and starves the
scout. Read what a clerk actually leaves in git (#424).

## Decisions

- Pending research.

## Rejected

- None yet.

## Review

- Pending.

## Blockers

None.

## Where to look

- `joharness.sh:clerk_due`, `cycle_landed_sha`, `scout_walk`, `cmd_dispatch`.
