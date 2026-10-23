---
workstream: reading-budget-always-loaded
status: in-progress
branch: claude/reading-budget-always-loaded
pr: none
plan: reading-budget-always-loaded
issue: none
session: https://claude.ai/code/session_01HMc9uadWhsxycSaAM98meV
agent: haiku
updated: 2026-10-23
next: Count the nine listed files with wc -c on this branch, add their rb_bound lines to .agents/harness/selftest/reading-budget.sh, run ./joharness.sh ci, push.
---

## Goal

Bound the always-loaded files that have no byte bound yet, so growth in them
is a decision made in a commit and not drift (plan `reading-budget-always-loaded`).

## Decisions

- Counts are taken on this branch at build time, never copied from the plan.
- Scope is the selftest file only; no core path (`joharness.conf`,
  `.claude/settings.json`, `.github`) is touched.

## Rejected

None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- `.agents/harness/selftest/reading-budget.sh:rb_bound` — the helper and its third argument (base dir).
