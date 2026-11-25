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
- r1: (verifier) re-run rule overrode a red in the diff; scoped to reds outside it (fixed)
- r2: (verifier) merge retry had no not-level branch; re-measures all of step 7, behind goes to § 4 (fixed)
- r3: (verifier) dated stories in a rule doc; moved to the commit message (fixed)
- r4: (verifier) budget raise said +86, counted +97; recounted (fixed)
- r5: (verifier) bound named local-check only; now plus ci and verify (fixed)
