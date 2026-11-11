---
workstream: retired-respawn-prompt
status: in-progress
branch: manager/retired-respawn-prompt
pr: none
plan: retired-respawn-prompt
issue: none
session: https://claude.ai/code/session_01J1YMK3ESUPtSD86bcqYoBC
agent: sonnet
updated: 2026-11-11
next: Verifier running; record its findings in ## Review, fix, then retire commit and PR.
---

## Goal

Give a retired branch's respawn a prompt and a manager rule it can follow (plan retired-respawn-prompt).

## Decisions

- A1: confirmed — Loop step 7 deletes the workstream file before the PR opens.
- A2: confirmed — only the `gone` edge row lands on a file-less branch.
- A3: confirmed — Loop step 7 says the PR body carries the recover command.
- Orchestrator byte bound: moved "`suspect a stopped fleet` decides nothing" into orchestrator-reference.md.

## Review

## Blockers

None.

## Where to look

- docs/plans/retired-respawn-prompt.md
