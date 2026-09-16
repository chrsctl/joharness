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
- So it is NOT in `joharness.sh`'s knob list at the top of the file. That
  list opens "Selection lives in joharness.conf", and a non-conf key under
  that sentence invites the conf entry the decision above rules out. The
  slots line names the variable where a reader meets it, and
  `orchestrate.md` carries the duty.
- The plan said the duty goes at the spawn step. Widened to BOTH steps
  while building: step 1 is where dispatch runs and so where the number is
  applied, step 3 is where the `@new` entry that supplies it is written. One
  line each; the fact and its use are two places and a reader arrives at
  either.
- A `@new` entry that step 2 archives or reports is still counted by step 1,
  because step 1 ran first. Said in the command file rather than engineered
  around: the pass runs one slot short and the next pass has it back, which
  is the safe direction, and re-running dispatch to win the slot back would
  read the fleet twice in one pass.

## Rejected

- Keying slot accounting on the workstream file's `session:` line. It names
  whoever last WROTE the file, so after a respawn it advertises a dead
  session until the successor claims — the same window this closes, reopened
  one field over. Recorded in issue #249 and now in the command file.

## Review

## Blockers

None.

## Where to look

- `joharness.sh`, at `n_slots` — the one assignment every verdict below
  reads. (Line numbers move; the variable does not.)
- `.claude/commands/orchestrate.md` step 1 — the dispatch invocation that
  carries the number; step 3's ledger paragraph — where the `@new` entry
  that supplies it is written.
- `.agents/harness/selftest/dispatch.sh` — the cases for this input, on the
  same fixture as the slot assertions above them (cap 4, alpha in flight).
