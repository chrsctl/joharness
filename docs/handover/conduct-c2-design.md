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
next: Prototype c2.sh works on 3 real stems (FINE); build trap fixtures, measure worst unit, write Findings
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

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — runner; no single-topic selector (per Echo).
- `.claude/commands/conduct.md` — graduation target.
