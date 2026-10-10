---
workstream: no-ceiling-on-one-item
status: in-progress
branch: manage/no-ceiling-on-one-item
pr: none
plan: no-ceiling-on-one-item
issue: "#298"
session: https://claude.ai/code/session_01VvHXon6n8wmdf5GBNCtBjb
agent: opus
updated: 2026-10-10
next: Settle the node against what PR 357 landed, graduate into orchestrate.md + orchestrated.md, delete node
---

## Goal

Research node `docs/research/no-ceiling-on-one-item.md` (issue #298): what
bounds the time and money one item may consume when every health signal
reads a steadily-billing manager as healthy? Settle it, graduate, delete.

## Decisions

- Item 1 (detector) already landed: PR 357, `CEILING?` report row,
  `JOHARNESS_MANAGER_HOURS`. Checked: `git show --stat 5f4e4bd9`.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — health table, `CEILING?` row.
- `.agents/docs/orchestrated.md` — knob table, `JOHARNESS_MANAGER_HOURS`.
- `joharness.sh:dispatch_claim_age_min` — what the ceiling reads.
