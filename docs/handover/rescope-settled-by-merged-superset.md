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
next: Run selftest + revert check, review with verifier, retire, PR
---

## Goal

Issue #300: a merged `done` rescope must settle a later key whose holders
are a subset of its key, unless a held plan's file changed since.

## Decisions

- Subset test is one helper, `dispatch_rescope_covers`, used by BOTH the
  in-flight `done | blocked` rows and the merged records: two readers of one
  rule would drift.
- Merged walk stops at the first (newest) record that settles; later ones
  add nothing to the verdict.
- Built by the manager directly, no workers: one function chain in one file
  plus its suite — splitting it would put two workers on a shared file.

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — overlap-bound block.
