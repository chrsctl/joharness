---
workstream: shallow-clone-reaches-authority
status: in-progress
branch: claude/shallow-clone-reaches-authority
pr: none
plan: shallow-clone-reaches-authority
issue: 439
session: https://claude.ai/code/session_01RXca2ZFK5BrCwuBp3oKkUV
agent: opus
updated: 2026-10-13
next: Run selftest, ci, verify; revert-check the shallow case; verifier review; finish
---

## Goal

A fresh shallow cloud session must not exit UNVERIFIED over a fetch it can
run itself, and an orchestrator must not spawn into that race (issue #439).

## Decisions

- Hook unshallow bound 40 s: Claude Code's documented default command-hook
  timeout is 600 s and SessionStart is not among the events it lowers
  (code.claude.com/docs/en/hooks, Common fields, read 2026-10-13);
  `.claude/settings.json` sets no `timeout`. Worst case of the block is now
  40 s (timeout, 124, no fallback) or a fast failure plus 15 s.
- Role-command unshallow bound: `timeout 300`, a Bash command, not a hook.
- Shallow verdict prints `run:` at column 0 so a role can match it as a line.

## Rejected

- None yet.

## Review

<!-- review pending -->

## Blockers

None.

## Where to look

- `joharness.sh:cmd_authority` — the UNVERIFIED branches.
- `.agents/harness/handover-context.sh` — shallow fetch block.
