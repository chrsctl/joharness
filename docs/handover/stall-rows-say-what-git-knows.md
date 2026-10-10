---
workstream: stall-rows-say-what-git-knows
status: in-progress
branch: manage/stall-rows-say-what-git-knows
pr: none
plan: stall-rows-say-what-git-knows
issue: 283
session: https://claude.ai/code/session_015AjcweMJ4sZHA4LAqqMhrM
agent: opus
updated: 2026-10-10
next: Research cmd_dispatch edge rows + verdict tail, then build per plan Scope
---

## Goal

Issue #283: `dispatch` says three things without evidence — `PR in flight`
(it never reads a PR), `respawn on the branch to FINISH it` on a STALL? edge
row (verdict belongs to orchestrate.md's health table), and nothing when the
whole fleet is silent and `main` frozen (a suspension, not N dead managers).

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — edge_rows text, verdict tail.
