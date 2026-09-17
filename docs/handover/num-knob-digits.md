---
workstream: num-knob-digits
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: num-knob-digits
issue: 260
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-17
next: Review the diff, then retire the plan and the workstream file and open the pull request
---

## Goal

`docs/plans/num-knob-digits.md`, issue #260. `num_knob` filters its value to
digits only and hands the result to bash arithmetic. `08` and `09` pass the
filter and then die on the octal literal rule; `010` passes and is silently
read as eight. Every knob goes through this one reader, including
`JOHARNESS_MAX_MANAGERS`, which is the cap, which is the human's money.

The failure is quieter than a crash and worse. Measured 2026-09-17:
`JOHARNESS_CHURN_THRESHOLD=08 ... dispatch` exits 0 and prints its whole
output, because `set -e` is not in force and the arithmetic dies inside a
command substitution — so the knob is left EMPTY and the line reads `one
file rewritten + times`.

## Decisions

- Mutations go into a COPY, or through `./joharness.sh mutate`, never the
  working tree. The last item's r18 was mine and nearly shipped a mutated
  file: a `git add -A` while an injection was applied staged it, and the
  restore fixed the tree and not the index.

## Rejected

- `docs/plans/orchestrated-run.md`, which the queue ranks first. Its one
  remaining deliverable needs run 3 to have stopped; re-counted
  2026-09-17T04:19Z, three managers `SESSION_STATUS_RUNNING` with
  `updated_at` inside the minute. Its other precondition is the human's.
- The edge branch naming pull request #10. Re-read from GitHub this session:
  `state: closed`, `merged: false`, closed 2026-08-21.

## Review

- r1: (session, method) the mutations went through `./joharness.sh mutate`,
  which puts the line back itself and proves the file is otherwise
  untouched. That is the last item's r18 applied rather than restated: there
  it was a hand-rolled injection into the working tree, and a `git add -A`
  while one was applied staged the mutated file. The repo already had the
  tool; I had not looked. (no change needed — recorded because the lesson is
  "use the tool", not "be careful", and the next session reads this.)
- r2: (session) the stderr helper was first written `2>&1 >/dev/null`, which
  does what I meant and is the spelling shellcheck reads as the classic
  mistake (SC2069) — and `ci` fails on warning level, so it would have gone
  red at the edge. (fixed — `{ ...; } 2>&1`, with the reason on the line so
  nobody 'simplifies' it back.)

## Blockers

None.

## Where to look

- `joharness.sh:num_knob` — the one reader, five lines.
- `joharness.sh:cmd_dispatch` — the caller that reproduces it fastest, and
  the command that PRINTS every knob it read.
