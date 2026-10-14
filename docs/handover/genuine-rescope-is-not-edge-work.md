---
workstream: genuine-rescope-is-not-edge-work
status: in-progress
branch: claude/genuine-rescope-is-not-edge-work
pr: none
plan: genuine-rescope-is-not-edge-work
issue: 492
session: https://claude.ai/code/session_012aeEK469hHzaddGFthH93A
agent: opus
updated: 2026-10-14
next: Research anchors in handover-context.sh and cmd_dispatch, then build
---

## Goal

A surveyor that finds holds GENUINE (status done, pr none, plan none, never
merged) must not read as edge work: no EDGE, no lead, a dispatch row saying
it holds no slot, and the orchestrator drops its ledger entry instead of
nudging it forever (issue #492).

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh:rank_of` — rank mapping.
- `joharness.sh:cmd_dispatch` — rescope in-flight loop.
