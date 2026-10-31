---
workstream: finding-routes-leads
status: in-progress
branch: claude/finding-routes-leads
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK4juJSACHPjU3DpzHJ
agent: sonnet
updated: 2026-10-31
next: ci, verify, review + verifier at haiku, PR, finish, merge
---

## Goal

Follow-up to PR #714: `finding routes` missed 3 of 4 real out-of-item
verdicts from merged chrsctl/gx workstream files (sent by a sibling session,
each re-run here against `fr_out_of_item`: (a) caught, (b)-(d) missed).

## Decisions

- A verdict saying the finding went out "as a lead" or "lead to the
  orchestrator" is out-of-item: the lead being the only record is the hole.
- `not (this|the|our|my) <target>` covers "not this branch's".

## Review

## Blockers

None.
