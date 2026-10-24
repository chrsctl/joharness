---
workstream: narrower-human-remainder
status: in-progress
branch: manage-narrower-human-remainder
pr: none
plan: narrower-human-remainder
issue: none
session: https://claude.ai/code/session_01Xw3aQEVPpwLY5RQK9oWRnx
agent: sonnet
updated: 2026-10-24
next: Read verifier result, record in ## Review, then retire plan+workstream files and open PR
---

## Goal

Make a clerk NARROWER verdict surface its human remainder (label, numbered options, `## Issue remainder`), and make `Refs` follow from the plan.

## Decisions

- A1-A4: confirmed by reading clerk.md, manage-reference.md, orchestrated.sh. A5: confirmed, `ci: pass` with the edits.
- Edits done in the five scope files; 5 new pins fail without the doc edits (stash test); ci pass, verify 0 failed.

## Review

- r1: manage-reference.md Plan issue paragraph left one over-long line (verifier) (fixed)
- r2: orchestrated.md human-review bullet was a comma splice (verifier) (fixed)
- r3: edge review of the five-file diff: no other defect found (no change)

## Blockers

None.

## Where to look

- `docs/plans/narrower-human-remainder.md`
