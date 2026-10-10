---
workstream: an-injection-live-under-a-dispatched-reader
status: in-progress
branch: claude/an-injection-live-under-a-dispatched-reader
pr: none
plan: an-injection-live-under-a-dispatched-reader
issue: none
session: https://claude.ai/code/session_013sNLp7abB3bjEtXFdikfuE
agent: opus
updated: 2026-10-10
next: Settle the placement (A/B/C/E), graduate the rule, delete the research file
---

## Goal

Settle docs/research/an-injection-live-under-a-dispatched-reader.md: which
file carries the rule that a working-tree mutation and a dispatched read-only
reader are mutually exclusive. Graduate the answer, delete the node.

## Decisions

- Pending.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/subagents.md` — declared graduation target.
- `.claude/agents/verifier.md` — reader-side candidate.
- `joharness.sh` `mutate` — the command that performs the revert.
