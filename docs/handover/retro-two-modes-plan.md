---
workstream: retro-two-modes-plan
status: in-progress
branch: claude/retro-two-modes-plan
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017pMbD2M6TccgTkfZh9TDpS
agent: opus
updated: 2026-10-25
next: Write plan retro-audit-and-trace, drop research conduct-concern-to-retro, ci, verifier, PR
---

## Goal

User: merge conduct and retro into one role with two modes. Audit finds
problems in merged work and only counts them; trace takes failures,
including what audit found, and files fixes. Replaces research
conduct-concern-to-retro.

## Decisions

- Plan waits on conduct-recent-sample (rewrites conduct's sampling) and
  conduct-c2-design (graduates into conduct.md).

## Rejected

- Building the merge now: it would conflict with conduct-recent-sample.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_conduct`, `joharness.sh:cmd_retro`: the two copies.
