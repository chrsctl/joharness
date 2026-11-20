---
workstream: template-issue-line
status: in-progress
branch: claude/clever-pascal-qz32iv
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK5fH2288GR1soijKET
agent: haiku
updated: 2026-11-20
next: Verifier, ci, PR, merge
---

## Goal

Follow-up of #790 (its r3/r9): plans/TEMPLATE.md's `issue:` line still gave
the old Closes/Refs rule (heading only). Point it at § Plan issue.

## Decisions

- Point to the rule instead of restating it, so it cannot drift again.

## Rejected

- None.

## Review

- r1: (verifier) template names `## Issue remainder` but has no such section to fill (fixed: says add the section, one line per part)
- r2: (verifier) "never Out of scope" reads as a second rule beside § Plan issue reading Out of scope (no change: Plan issue reads Out of scope as a safety net; the checker reds a human part there)
- r3: (verifier) Goal cites #790 with `issue: none` (no change: #790 is a merged pull request, not an issue to claim)

## Blockers

None.

## Where to look

- `.agents/docs/plans/TEMPLATE.md` `issue:` line.
