---
workstream: heredoc-cpu-bound
status: in-progress
branch: claude/heredoc-cpu-bound
pr: none
plan: heredoc-cpu-bound
issue: 566
session: https://claude.ai/code/session_018FNpTGRJapDHTuQhgkbGwR
agent: sonnet
updated: 2026-10-23
next: Switch the heredoc case to a CPU-time bound, prove it, finish, then merge PR #565
---

## Goal

Issue #566: the heredoc timing case reds `lint` on pull request runs. User's
order: fix it, then merge PR #565 (parked on #566).

## Decisions

- Bound CPU time (user + sys), not wall clock: the case tells linear from
  quadratic (0.6 s vs 67 s), and CPU time does not grow with runner load.

## Rejected

- Raising the wall-clock bound: the earlier raise to 15 s was outrun by
  runner load; any number is a guess at someone else's load.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/selftest/pretool-bash-guard.sh` — the heredoc case.
