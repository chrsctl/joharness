---
workstream: rescope-settled-by-merged-superset
status: in-progress
branch: claude/rescope-settled-by-merged-superset
pr: none
plan: rescope-settled-by-merged-superset
issue: 300
session: https://claude.ai/code/session_01G5BQQShzZLen4fbuJHnfNY
agent: opus
updated: 2026-10-10
next: Research cmd_dispatch overlap-bound block, then implement subset settle + merged-rescope helper
---

## Goal

Issue #300: a merged `done` rescope must settle a later key whose holders
are a subset of its key, unless a held plan's file changed since.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — overlap-bound block.
