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
next: Measure selftest runner shape and per-case isolation; fill Method and Findings
---

## Goal

Settle docs/research/conduct-c2-design.md: can conduct check, per sampled
branch, that the selftest case a fix added fails on the pre-fix parent,
without false FINE or false CONCERN, at a cost of 3 branches per run.

## Decisions

None yet.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — runner; no single-topic selector (per Echo).
- `.claude/commands/conduct.md` — graduation target.
