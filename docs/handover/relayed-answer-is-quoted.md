---
workstream: relayed-answer-is-quoted
status: in-progress
branch: manage/relayed-answer-is-quoted
pr: none
plan: relayed-answer-is-quoted
issue: 426
session: https://claude.ai/code/session_01BrGNHzCYCmJpsPdgCmgSmJ
agent: sonnet
updated: 2026-10-12
next: Await verifier (a7f471098ef8d6f72), record ## Review, retire plan+workstream, PR, merge
---

## Goal

Agent-footed comments never reopen a clerk-verdict issue; orchestrator posts nothing on GitHub (plan relayed-answer-is-quoted).

## Decisions

- Two small edits by hand; no workers needed.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/clerk.md` §2, §3; `.claude/commands/orchestrate.md` Never.
