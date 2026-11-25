---
workstream: finish-wait-and-merge-retry
status: in-progress
branch: claude/finish-wait-and-merge-retry
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK5AqVCVH5DbDYhxHr1
agent: haiku
updated: 2026-11-25
next: ci, verify, verifier at haiku, PR, finish, merge; then sync to the consumer
---

## Goal

Managers take hours to finish. A consumer's five manager transcripts
(2026-11-25) put the harness-owned losses at: a merge call's 5xx makes the
manager exit by rule (about 2 h idle, then a fresh full run), and waits on
`finish` set by clock, so a green sits unread while the base moves.

## Decisions

- manager.md § 4: wait on `finish` by its exit; no hand run of what
  local-check reruns; a merge call retries three times before the
  GitHub-lost rule.
- Out of this lane (reported to the requester, not built): parking on a red
  outside the diff, a scoped RETEST as long as a full run, the consumer's own
  local-check costs.

## Review
