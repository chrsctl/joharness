---
workstream: role-command-trim
status: in-progress
branch: claude/role-command-trim
pr: none
plan: role-command-trim
issue: none
session: https://claude.ai/code/session_016g6mN8LJQwpLQLRc1Rmond
agent: opus
updated: 2026-10-10
next: Research anchors, then ctx_report block + selftest, then move why-text out of orchestrate.md/manage.md
---

## Goal

Requester, 2026-10-09: "Is there anything to optimize also regarding the
existing harness files" — move why-text and incident history out of the
role command files into `.agents/docs/orchestrated.md`, keep every
instruction, and make `./joharness.sh context` count the role files.

## Decisions

- Baseline at claim (`wc -w`, 2026-10-10, origin/main a243fb04):
  orchestrate.md 10,080; manage.md 2,347; orchestrated.md 12,677.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:ctx_report` — role-file block.
