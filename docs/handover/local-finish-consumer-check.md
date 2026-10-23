---
workstream: local-finish-consumer-check
status: in-progress
branch: claude/local-finish-consumer-check
pr: none
plan: local-finish-consumer-check
issue: none
session: https://claude.ai/code/session_01473SJGCfbPForWe43xj3sc
agent: opus
updated: 2026-10-23
next: Research checks_gate in joharness.sh, then add the local-check run and its selftests
---

## Goal

Under `JOHARNESS_CHECKS=local`, let a consumer put ONE command
(`local-check` at its repository root) behind `finish: pass`, so its own
required checks gate the merge instead of prose (gx #785).

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — the local-mode gate this extends.
