---
workstream: rules-apart-from-history
status: in-progress
branch: claude/rules-apart-from-history
pr: none
plan: rules-apart-from-history
issue: none
session: https://claude.ai/code/session_01CZV2rPC7c6hTKerRBsEuLj
agent: opus
updated: 2026-10-14
next: Split handover/README.md and consumer-repos.md into rules plus history files
---

## Goal

Move measurement, incident narrative and rejected alternatives out of
`.agents/docs/handover/README.md` and `.agents/docs/consumer-repos.md` into
append-only `.agents/docs/history/` files, each rule keeping a `(why: …)`
pointer; bound the two files in a new selftest case.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- Not yet reviewed.

## Blockers

None.

## Where to look

- `docs/plans/rules-apart-from-history.md` — the plan.
