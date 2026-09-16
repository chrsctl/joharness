---
workstream: pending-spawns
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: pending-spawns
issue: 255
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Build the pending input and the rule that supplies it, review, retire, open the pull request
---

## Goal

Issue #255. `dispatch` derives its slot count from the git view, so a manager
spawned minutes ago is invisible until it pushes its claim — measured 3 to 12
minutes. Twice in one evening the count read a free slot that was already
owned. Nothing reconciled the two views; the only thing that knew was an
orchestrator keeping its own notes.

## Decisions

- The issue offers three routes and prefers the second. Taking it, plus the
  first, because they are not alternatives: an input nobody is told to
  supply is never supplied. So `dispatch` gains the input, and
  `orchestrate.md` gains the duty to pass it, in one change.
- Route three, reconciling from the control plane inside `dispatch`, is
  rejected for the reason the issue gives: `dispatch` is the git view, and
  pulling session state into it collapses the "two signals, never one"
  separation the health table rests on.
- The input can only LOWER the count. That is the safe direction: a count
  too high spends a manager over the cap, which is the human's money, while
  a count too low costs one pass of one spawn.
- Read from the ENVIRONMENT only, never `joharness.conf`. Every other number
  here is a repo-level setting a conf legitimately carries; this one is a
  fact about one pass, and a stale conf value would silently under-report
  slots for ever with nothing to notice it.

## Rejected

- Keying slot accounting on the workstream file's `session:` line. It names
  whoever last WROTE the file, so after a respawn it advertises a dead
  session until the successor claims — the same window this closes, reopened
  one field over. Recorded in issue #249 and now in the command file.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:7437` — `n_slots`, the one line every verdict below reads.
- `.claude/commands/orchestrate.md` step 3 — where a spawn happens, and so
  where the duty to count it belongs.
