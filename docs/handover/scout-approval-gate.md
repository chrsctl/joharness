---
workstream: scout-approval-gate
status: in-progress
branch: manage/scout-approval-gate
pr: none
plan: scout-approval-gate
issue: none
session: https://claude.ai/code/session_01YYwcbvf34XMV2YVjh6fxBL
agent: opus
updated: 2026-10-12
next: Run ci + verify, verifier review, retire, PR
---

## Goal

A scout proposal reaches plans only after the reviewer's `approved` label
event newer than the proposal's last revision; scout-origin pull requests
carry the `scout:` title prefix and `scout` label.

## Decisions

- Edits written directly, no workers: three short prose edits whose wording
  must agree with each other; splitting them costs more than it buys.
- Last revision with no scout comment = the issue's creation; the newest
  `approved` labeled event must be the reviewer's (a later relabel by
  anyone else fails closed).
- A proposal passing the scout gate still meets the skip list and author
  gate: the plan adds a gate, never removes one.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/clerk.md` — §2 author gate, §4 pull request.
