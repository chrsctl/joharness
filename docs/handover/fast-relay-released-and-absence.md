---
workstream: fast-relay-released-and-absence
status: in-progress
branch: claude/fast-relay-released-and-absence
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK7DeCwe2BzZTZiV1dF
agent: haiku
updated: 2026-11-26
next: Run ci, verify, haiku verifier; retire this file; PR; finish; merge
---

## Goal

The human asked to fix the two consumer reports from chrsctl/gx (#795: Relay
misses a released `product:` block; #796: a refuted absence accepted without
the finding command) through the fast lane, merge, and sync back.

## Decisions

- Relay rule widened in prose (orchestrator-reference.md § Relay); the
  orchestrator applies it, so no script change.
- Absence rule in plans.md § Shape, Assumptions: manager.md §2 is at its
  reading budget (ci: 10497 bytes, bound 10279), and plans.md defines the
  `A<n>` line the manager confirms or refutes.

## Review

## Blockers

None.
