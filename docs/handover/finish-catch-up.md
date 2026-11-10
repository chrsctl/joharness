---
workstream: finish-catch-up
status: in-progress
branch: claude/finish-catch-up
pr: none
plan: finish-catch-up
issue: none
session: https://claude.ai/code/session_01J1YMK5e4qFM7qu8dpzkfv1
agent: opus
updated: 2026-11-10
next: Build checks_gate catch-up certificate per docs/plans/finish-catch-up.md, then selftest cases
---

## Goal

gx PR #1417: a local-mode finish (~27 min) can never win the race to 0
behind on a busy base; the manager gave up leaving a green non-draft PR,
merged 172 stale by a human, main went red. Fix the starvation (catch-up
certification) and the exit (draft + `conflict:` block).

## Decisions

- Same-session plan (`.agents/docs/plans.md`, Lifecycle): the task arrived
  as a direct ask; plan lives on this branch, deleted at retire.

## Rejected

- Orchestrator-granted merge slot: new state, and still 27 min per slot.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — certificate and catch-up.
