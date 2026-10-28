---
workstream: conduct-c2-design
status: in-progress
branch: research/conduct-c2-design
pr: none
plan: conduct-c2-design
issue: none
session: https://claude.ai/code/session_01J1YMK7QGg4E4RrtuYft1bf
agent: opus
updated: 2026-10-28
next: Read scratchpad run-c.txt; fill research Findings with its numbers; ci; verifier; retire
---

## Goal

Settle docs/research/conduct-c2-design.md: can conduct check, per sampled
branch, that the selftest case a fix added fails on the pre-fix parent,
without false FINE or false CONCERN, at a cost of 3 branches per run.

## Decisions

- Design: T_fix = last retire tree; T_nofix = T_fix with the stem's own
  non-merge commits reverted (3-way) and selftest files restored from T_fix;
  run only the units holding touched topics, read each label's own word.
  Why: tests from T_fix kill the missing-helper and unlisted-topic traps.
- Verdict is per case, read against the Goal: the fixture `other` (an
  unrelated case flips, the fix's own case passes either way) gives a
  mechanical FINE that only the per-case table exposes.

## Rejected

- `git revert` of own commits: conflicts in test files it then discards.
- `git apply -R --3way` of own non-test diffs onto T_fix: conflicts when
  main merged into the branch moved the same lines
  (requirement-partly-served, 970de5c1 against joharness.sh).
- Code from the main commit the branch last merged replaces both reverts;
  `--ancestry-path --first-parent` to find that merge returned nothing for
  guard-one-shot-self-kill (it merged main after its retire): loop instead.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — runner; no single-topic selector (per Echo).
- `.claude/commands/conduct.md` — graduation target.
