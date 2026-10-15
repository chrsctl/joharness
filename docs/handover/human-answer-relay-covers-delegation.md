---
workstream: human-answer-relay-covers-delegation
status: in-progress
branch: manage-human-answer-relay
pr: none
plan: human-answer-relay-covers-delegation
issue: none
session: https://claude.ai/code/session_01USonUprubk5GGRXfwYMqJP
agent: sonnet
updated: 2026-10-15
next: ci rerun, PR, check GitHub checks; retire plan + this file in last commit
---

## Goal

Plan `docs/plans/human-answer-relay-covers-delegation.md`.

## Decisions

- Two small page edits; done inline, no workers.

## Review

- r1: (verifier) blocked row sat below the RUNNING rows, so a RUNNING blocked manager never reached it; row moved above them (fixed)
- r2: (verifier) INVALID BLOCK? row still says not RUNNING, RUNNING invalid block falls through (wontfix: pre-existing row, outside plan scope)
- r3: (verifier) alive-arm NUDGE lacked a no-transport clause; added (fixed)
- r4: (verifier) relay not tied to an answer being present; row now says relay only when answer or delegation is in YOUR turn (fixed)

## Blockers

ci selftest `80 KB of prose keywords` takes 5s vs 4s bound on this machine, 3 of 3 alone; script untouched by this diff. GitHub checks decide.

None.

## Where to look

- `.claude/commands/orchestrate.md:152` — the blocked row.
