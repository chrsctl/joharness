---
workstream: push-age-is-not-death
status: in-progress
branch: claude/push-age-is-not-death
pr: none
plan: push-age-is-not-death
issue: "#283"
session: https://claude.ai/code/session_01F6UGCmZwiRAyMXPraicZSa
agent: opus
updated: 2026-10-10
next: Settle the research node — read cmd_dispatch edge STALL? row, decide replacement text, graduate into joharness.sh
---

## Goal

Research node `docs/research/push-age-is-not-death.md` (issue #283): may the
scheduler print a respawn instruction on a row whose only evidence is the
age of the branch's last commit? Settle it, graduate the answer into
`joharness.sh`, delete the node.

## Decisions

- (pending)

## Rejected

- (none yet)

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — edge `STALL?` row and `PR in flight` row.
- `joharness.sh:dispatch_age_min` — the age behind the row.
