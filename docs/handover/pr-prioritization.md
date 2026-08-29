---
workstream: pr-prioritization
status: in-progress
branch: claude/pr-prioritization-ff09tx
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-29
next: Research the queue/handover hooks, then write docs/plans/ for PR prioritization before any code
---

## Goal

Human asked whether the harness has anything for PR prioritization, then
asked to research and implement it. Answer to the question was no: urgency
ranking exists for work a session would START (plans, requirements,
research questions) and nothing ranks or surfaces work already in flight.

## Decisions

- Claiming before the plan exists: step 2 says decompose first, but step 3
  says push the claim before touching code. Plan file lands on this branch
  (same-session plan, allowed by plans README Lifecycle).

## Rejected

- None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh` — the rank function urgency feeds.
- `.agents/harness/handover-context.sh` — the in-flight branch view.
