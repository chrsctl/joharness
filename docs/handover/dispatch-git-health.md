---
workstream: dispatch-git-health
status: in-progress
branch: manage/dispatch-git-health
pr: none
plan: dispatch-prints-the-git-half-of-health
issue: none
session: https://claude.ai/code/session_013egFD4ouUukESSjmymzftc
agent: sonnet
updated: 2026-10-13
next: Verify (selftest, ci, verify) the uncommitted head/base edits, then verifier review, retire, PR
---

## Goal

Plan dispatch-prints-the-git-half-of-health: in-flight rows print head sha and base ok|unreadable.

## Review

- r1: (verifier) orphan-fixture teardown `out=` was never read (fixed: now refutes a leaked `base unreadable`)
- r2: (verifier) LOOP? assertion lost its row binding (fixed: now matches `base ok  LOOP? ...`)
- r3: (verifier) `base unreadable` also covers an absent branch ref; orchestrate.md row says report, decide nothing (no change)

## Blockers

None.
